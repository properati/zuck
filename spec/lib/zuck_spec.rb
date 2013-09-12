require 'spec_helper'

describe Zuck::FbObject do

  before(:all) do
    Zuck.graph = Koala::Facebook::API.new(test_access_token)
  end

  let(:graph)   { Zuck.graph                                                  }
  let(:account) { Zuck::AdAccount.new(graph,  {id: "act_10150585630710217"})  }
  let(:campaign){ Zuck::AdCampaign.new(graph, {id: "6010888547351"}, account) }
  let(:group)   { Zuck::AdGroup.new(graph,    {id: "6004497037951"}, campaign)}
  let(:creative){ Zuck::AdCreative.new(graph, {id: "6004501081751"}, group)   }


  describe "read only objects" do
    it "can't be created" do
      expect{
        Zuck::AdCreative.create(:x, {}, :y)
      }.to raise_error(Zuck::Error::ReadOnly)
    end

    it "can't be saved" do
      expect{
        creative.save
      }.to raise_error(Zuck::Error::ReadOnly)
    end

    it "can't be destroyed" do
      expect{
        creative.destroy
      }.to raise_error(Zuck::Error::ReadOnly)
    end
  end

  describe "talking to facebook" do
    context "reading" do

      it "a list of ad accounts" do
        VCR.use_cassette('list_of_ad_accounts') do
          Zuck::AdAccount.all.should have(1).item
        end
      end

      it "a list of ad campaigns" do
        VCR.use_cassette('list_of_ad_campaigns') do
          account.ad_campaigns.should have(1).items
        end
      end

      it "a list of ad groups" do
        VCR.use_cassette('list_of_ad_groups') do
          campaign.ad_groups.should have(1).item
        end
      end

      it "list of ad creatives" do
        VCR.use_cassette('list_of_ad_creatives') do
          group.ad_creatives.should have(1).items
        end
      end

      it "list of all ad creatives of an account" do
        g = graph
        Zuck::AdAccount.should_receive(:all).and_return([account])
        VCR.use_cassette('list_of_all_ad_creatives_of_account') do
          Zuck::AdCreative.all(g).should have(3).items
        end
      end

      context "an id directly" do

        it "with the correct type" do
          VCR.use_cassette('a_single_campaign') do
            c = Zuck::AdCampaign.find(6005950787751, graph)
          end
        end

        it "with the correct type" do
          VCR.use_cassette('a_single_account') do
            c = Zuck::AdAccount.find('act_10150585630710217', graph)
          end
        end

        it "when expecting an ad group but the id belongs to a campaign" do
          expected_error = <<-END_ERROR
Invalid type.

Expected data['id']="6005950787751" to be equal to one of these:
  * data['account_id']="10150585630710217"
  * data['group_id']=nil
  * data['adgroup_id']=nil
END_ERROR
          VCR.use_cassette('a_single_campaign') do
            expect{
              c = Zuck::AdGroup.find(6005950787751, graph)
            }.to raise_error(expected_error)
          end
        end

        it "and saving it" do
          VCR.use_cassette('find_a_single_campaign_and_update_it') do
            group = Zuck::AdGroup.find(6005859287551, graph)
            group.name = "My old name"
            group.save
            group.name.should == "My old name"
            group.name = "My new name"
            group.save
            group.name.should == "My new name"
            group.reload
            group.name.should == "My new name"
          end
        end

      end
    end


    context "creating" do
      it "an ad campaign" do
        VCR.use_cassette('create_ad_campaign') do
          o = {daily_budget: 1000, name: "bloody" }
          campaign = Zuck::AdCampaign.create(graph, o, account)
          campaign.name.should == "bloody"
        end
      end

      it "an ad campaign via an existing ad account" do
        VCR.use_cassette('create_ad_campaign') do
          o = {daily_budget: 1000, name: "bloody" }
          campaign = account.create_ad_campaign(o)
          campaign.name.should == "bloody"
        end
      end

      it "an ad group" do
        VCR.use_cassette('create_ad_group') do
          o = {bid_type: 'CPC', max_bid: 1, name: "Rap like me", targeting: '{"countries":["US"]}',
               creative: '{"type":25,"action_spec":{"action.type":"like", "post":10150420410887685}}'}
          group = Zuck::AdGroup.create(graph, o, campaign)
          group.name.should == "Rap like me"
        end
      end

      it "an ad group via an existing ad campaign" do
        VCR.use_cassette('create_ad_group') do
          o = {bid_type: 'CPC', max_bid: 1, name: "Rap like me", targeting: '{"countries":["US"]}',
               creative: '{"type":25,"action_spec":{"action.type":"like", "post":10150420410887685}}'}
          group = campaign.create_ad_group(o)
          group.name.should == "Rap like me"
          group.bid_type.should == 'CPC'
        end
      end
    end

    context "deleting" do
      it "an ad group" do
        VCR.use_cassette('delete_ad_group') do
          group.destroy.should be_true
        end
      end
    end

  end
end
