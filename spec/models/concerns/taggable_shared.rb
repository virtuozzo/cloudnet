shared_examples_for "taggable" do
  let(:model) { described_class } # the class that includes the concern
  let(:object) { FactoryGirl.create(model.to_s.underscore.to_sym) }
  let(:object2) { FactoryGirl.create(model.to_s.underscore.to_sym) }
  let(:tag) { FactoryGirl.create(:tag) }
  
  it 'shows tag labels' do
    expect(object.tag_labels).to be_empty
    object.tags << FactoryGirl.create_list(:tag, 3)
    expect(object.tag_labels.count).to eq 3
  end
  
  it 'doesnt allow duplicate tags' do
    object.tags << tag
    expect { object.tags << tag }.to raise_error(ActiveRecord::RecordNotUnique)
    expect(object.tags.count).to eq 1
  end
  
  it 'doesnt allow for tags with the same label' do
    tag1 = Tag.new(label: 'same')
    tag2 = Tag.new(label: 'same')
    expect {object.tags << tag1 << tag2}.to raise_error(ActiveRecord::RecordNotUnique)
  end
  
  it 'adds and saves new tags' do
    t = FactoryGirl.build(:tag)
    expect {object.tags << t}.to change {Tag.count}
  end

  context 'tag and bindings removal' do
    before(:each) do
      tag_list = FactoryGirl.create_list(:tag, 2)
      object.tags << tag_list
      object2.tags << tag_list
    end
    
    def binding_removal_initial_state
      expect(object.tags.count).to eq 2
      expect(object2.tags.count).to eq 2
      expect(Tag.count).to eq 2
      expect(Tagging.count).to eq 4
    end
    
    def binding_removal_final_state
      expect(object.tags.count).to eq 1
      expect(object2.tags.count).to eq 1
      expect(Tag.count).to eq 1
      expect(Tagging.count).to eq 2
    end
    
    shared_examples "binding removal" do |method|
      it 'destroys tag and all bindings to this tag' do
        binding_removal_initial_state
        object.tags.first.send(method)
        binding_removal_final_state
      end
      
      it 'removes bindings to the tag' do
        binding_removal_initial_state
        Tag.first.send(method)
        binding_removal_final_state
      end
    end
    
    context '#destroy' do
      it_behaves_like 'binding removal', :destroy
    end
    
    context '#delete' do
      it_behaves_like 'binding removal', :delete
    end
  end
  
  context 'removing taggings' do
    before(:each) do
      tag_list = FactoryGirl.create_list(:tag, 2)
      object.tags << tag_list << FactoryGirl.create_list(:tag, 2)
      object2.tags << tag_list << tag << FactoryGirl.create_list(:tag, 2)
    end

    it 'removes only binding leaving the Tag' do
      object.tags << tag
      expect(tag.taggings.count).to eq 2
      tag_count = Tag.count
      expect {object.remove_tagging(tag)}.to change{Tagging.count}.by(-1)
      expect(Tag.count).to eq tag_count
      expect {object2.remove_tagging(tag)}.to change{Tagging.count}.by(-1)
      expect(Tag.count).to eq tag_count
      expect(tag.taggings.count).to eq 0
    end
    
    it 'returns number of taggings removed' do
      expect(object2.remove_tagging(Tag.new(label: 'dd'))).to eq 0
      expect(object2.remove_tagging(tag)).to eq 1
      expect(object.remove_tagging(tag)).to eq 0
    end
  end
end