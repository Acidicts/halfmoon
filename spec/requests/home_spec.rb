# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Homes', type: :request do
  describe 'GET /' do
    it 'returns http success' do
      get '/'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /about' do
    it 'returns http success' do
      get '/about'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /rsvp' do
    context 'when not authenticated' do
      it 'returns http success' do
        get '/rsvp'
        expect(response).to have_http_status(:success)
      end
    end

    context 'when authenticated' do
      let(:user) { create(:user) }

      before do
        allow_any_instance_of(HomeController).to receive(:current_user).and_return(user)
      end

      it 'returns http success' do
        get '/rsvp'
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /rsvp' do
    context 'when not authenticated' do
      it 'redirects to sign in and stores the pending RSVP action' do
        post '/rsvp'
        expect(response).to redirect_to(new_session_path)
        expect(session[:pending_action_after_authenticating]).to eq({ "method" => "POST", "path" => rsvp_path })
        expect(session[:return_to_after_authenticating]).to eq(rsvp_path)
      end
    end

    context 'when authenticated' do
      let(:user) { create(:user) }

      before do
        allow_any_instance_of(HomeController).to receive(:current_user).and_return(user)
        allow(SlackBotService).to receive(:add_to_channel).and_return(true)
      end

      it 'creates an rsvp and redirects to the thanks page' do
        expect { post '/rsvp' }.to change(Rsvp, :count).by(1)
        expect(response).to redirect_to(rsvp_thanks_path)
      end

      it 'does not create a duplicate rsvp' do
        create(:rsvp, user: user)

        expect { post '/rsvp' }.not_to change(Rsvp, :count)
        expect(response).to redirect_to(rsvp_thanks_path)
      end

      it 'invites the user to Slack' do
        post '/rsvp'
        expect(SlackBotService).to have_received(:add_to_channel).with(slack_id: user.slack_id)
      end

      it 'still rsvps when the Slack invite fails' do
        allow(SlackBotService).to receive(:add_to_channel).and_return(false)

        expect { post '/rsvp' }.to change(Rsvp, :count).by(1)
        expect(response).to redirect_to(rsvp_thanks_path)
      end

      it 'still rsvps when the Slack invite raises' do
        allow(SlackBotService).to receive(:add_to_channel).and_raise(StandardError, "boom")

        expect { post '/rsvp' }.to change(Rsvp, :count).by(1)
        expect(response).to redirect_to(rsvp_thanks_path)
      end

      it 'still rsvps when the user has no slack_id' do
        user.update!(slack_id: nil)

        expect { post '/rsvp' }.to change(Rsvp, :count).by(1)
        expect(response).to redirect_to(rsvp_thanks_path)
        expect(SlackBotService).to have_received(:add_to_channel).with(slack_id: nil)
      end
    end
  end

  describe 'GET /rsvp/thanks' do
    it 'returns http success' do
      get '/rsvp/thanks'
      expect(response).to have_http_status(:success)
    end

    context 'when the user has a legacy unencrypted name' do
      it 'renders the thanks page without a decryption error' do
        user = create(:user)
        # Simulate data written before encryption was enabled: raw plaintext in the column.
        ActiveRecord::Base.connection.update("UPDATE users SET name = 'Alex' WHERE id = #{user.id}")
        # Fresh record so the name is read from the column (not the identity-map cache).
        user = User.find(user.id)
        allow_any_instance_of(HomeController).to receive(:current_user).and_return(user)

        expect { get '/rsvp/thanks' }.not_to raise_error
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Thanks for RSVPing, Alex")
      end
    end
  end
end
