require 'rails_helper'

describe UtmTracker do
  
  let(:param1) {{
                  "utm_source"=>"source_example", 
                  "utm_medium"=>"medium_example", 
                  "utm_term"=>"term_example", 
                  "utm_content"=>"content_example", 
                  "utm_campaign"=>"campaign_cool",
                  "controller"=>"public",
                  "other_par"=> 4
                }}
  let(:param2) {{
                  "utm_source"=>"source_example", 
                  "utm_medium"=>"medium_example", 
                  "utm_campaign"=>"campaign_cool",
                  "controller"=>"public",
                  "other_par"=> 4
                }}
              
  let(:result1) {{
                  utm_source: "source_example", 
                  utm_medium: "medium_example", 
                  utm_term: "term_example", 
                  utm_content: "content_example", 
                  utm_campaign: "campaign_cool"
                }}
  let(:result2) {{
                  utm_source: "source_example", 
                  utm_medium: "medium_example", 
                  utm_term: nil, 
                  utm_content: nil, 
                  utm_campaign: "campaign_cool"
                }}
  it "should extract proper params and return them" do
    expect(UtmTracker.extract_properties(param1)).to eq result1
  end
  
  it "should extract available params and return them" do
    expect(UtmTracker.extract_properties(param2)).to eq result2
  end
end