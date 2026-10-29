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
    end
  end

  describe 'GET /rsvp/thanks' do
    it 'returns http success' do
      get '/rsvp/thanks'
      expect(response).to have_http_status(:success)
    end
  end
end
