# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#flash_alert_type' do
    it 'maps flash keys to alert kinds' do
      expect(helper.flash_alert_type(:notice)).to eq('success')
      expect(helper.flash_alert_type('success')).to eq('success')
      expect(helper.flash_alert_type(:alert)).to eq('error')
      expect(helper.flash_alert_type(:error)).to eq('error')
      expect(helper.flash_alert_type(:warning)).to eq('warn')
      expect(helper.flash_alert_type('warn')).to eq('warn')
      expect(helper.flash_alert_type(:info)).to eq('info')
      expect(helper.flash_alert_type(:unknown)).to eq('info')
    end
  end
end
