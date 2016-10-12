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

  context '#add_tags_by_label' do
    it 'creates new tags and binds to a model' do
      existing_label = tag.label
      expect(object.tags).to be_empty
      expect {object.add_tags_by_label(:new_tag, existing_label, 'second new')}.to change {Tag.count}.by(2)
      expect(object.tags.count).to eq 3
    end

    it 'creates new tags as array and binds to a model' do
      existing_label = tag.label
      expect(object.tags).to be_empty
      expect {object.add_tags_by_label([:new_tag, existing_label], 'second new')}.to change {Tag.count}.by(2)
      expect(object.tags.count).to eq 3
    end

    it 'doesnt raise error if tags already added' do
      existing_label = tag.label
      object.tags << tag
      expect(object.tags.count).to eq 1
      expect {object.add_tags_by_label(existing_label)}.not_to raise_error
      expect(object.tags.count).to eq 1
    end

    it 'returns only added tags' do
      object.tags << tag
      expect(object.tags.count).to eq 1
      result = object.add_tags_by_label(:non_existing_label, tag.label)
      expect(object.tags.count).to eq 2
      expect(result).to eq ['non_existing_label']
    end

    it 'skips nil values' do
      existing_label = tag.label
      object.tags << tag
      expect {object.add_tags_by_label(nil, existing_label, nil)}.not_to raise_error
      expect(object.tags.count).to eq 1
    end
  end

  context '#remove_tags_by_label' do
    it 'removes tags bindings from a model' do
      tag1 = Tag.new(label: 'one')
      tag2 = Tag.new(label: 'two')
      object.tags << tag << tag1 << tag2
      expect(object.tags.count).to eq 3
      expect {object.remove_tags_by_label(tag.label, tag2.label)}.not_to change {Tag.count}
      object.reload
      expect(object.tags.count).to eq 1
      expect(object.tags.first).to eq tag1
    end

    it 'removes tags as array from a model' do
      tag1 = Tag.new(label: 'one')
      tag2 = Tag.new(label: 'two')
      tag3 = Tag.new(label: 'three')
      object.tags << tag << tag1 << tag2
      expect(object.tags.count).to eq 3
      expect {object.remove_tags_by_label([tag.label, tag2.label], tag3.label)}.not_to change {Tag.count}
      object.reload
      expect(object.tags.count).to eq 1
      expect(object.tags.first).to eq tag1
    end

    it 'doesnt raise error if non existing tag' do
      object.tags << tag
      expect(object.tags.count).to eq 1
      expect {object.remove_tags_by_label(:non_existing_label)}.not_to raise_error
      expect(object.tags.count).to eq 1
    end

    it 'returns only removed tags' do
      object.tags << tag
      expect(object.tags.count).to eq 1
      result = object.remove_tags_by_label(:non_existing_label, tag.label)
      expect(object.tags.count).to eq 0
      expect(result).to eq [tag.label]
    end

    it 'skips nil values' do
      tag1 = Tag.new(label: 'one')
      tag2 = Tag.new(label: 'two')
      object.tags << tag << tag1 << tag2
      expect(object.tags.count).to eq 3
      expect {object.remove_tags_by_label(nil, :non_existing, tag.label, nil)}.not_to change {Tag.count}
      expect(object.tags.count).to eq 2
    end
  end

  context '#add_remove_tags_by_hash' do
    it 'returns false if not Hash sent' do
      expect(object.add_remove_tags_by_hash([label1: true, label2: true])).to be_falsey
    end

    it 'returns false if not only true/false as values' do
      expect(object.add_remove_tags_by_hash(label1: true, label2: 'abc')).to be_falsey
    end

    it 'adds new tags to the model' do
      expect(object.tags).to be_empty
      expect {object.add_remove_tags_by_hash(label1: true, label2: true)}.to change {Tag.count}.by(2)
      expect(object.tags.count).to eq 2
    end

    it 'removes tags from the model' do
      tag1 = Tag.new(label: 'one')
      tag2 = Tag.new(label: 'two')
      object.tags << tag << tag1 << tag2
      expect(object.tags.count).to eq 3
      expect {object.add_remove_tags_by_hash(tag1.label.to_s => false)}.not_to change {Tag.count}
      expect(object.tags.count).to eq 2
    end

    it 'removes and adds tags to the model' do
      tag1 = Tag.new(label: 'one')
      tag2 = Tag.new(label: 'two')
      object.tags << tag << tag1 << tag2
      expect(object.tags.count).to eq 3
      expect {object.add_remove_tags_by_hash(
          {
            tag1.label.to_s => false,
            tag2.label.to_s => true,
            new_one: true,
            for_remove: false,
            another: true
          }
        )}.to change {Tag.count}.by(2)
      expect(object.tags.count).to eq 4
    end

    it 'returns only added and removed tags' do
      tag1 = Tag.new(label: 'one')
      tag2 = Tag.new(label: 'two')
      object.tags << tag << tag1 << tag2
      expect(object.tags.count).to eq 3
      result = object.add_remove_tags_by_hash(
          {
            tag1.label.to_s => false,
            tag2.label.to_s => true,
            new_one: true,
            for_remove: false,
            another: true
          })
      expect(result).to eq [{:added=>["new_one", "another"], :removed=>["one"]}]
    end
  end
end