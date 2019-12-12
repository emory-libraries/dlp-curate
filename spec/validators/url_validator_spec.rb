# frozen_string_literal: true

require 'rails_helper'

module Test
  UrlValidatable = Struct.new(:link_url, :link_array) do
    include ActiveModel::Validations
    validates :link_url, :link_array, url: true
  end
end

describe UrlValidator, type: :model do
  subject(:work) { Test::UrlValidatable.new }

  context 'not a url' do
    it 'link_url is invalid' do
      work.link_url = 'teststring'
      work.link_array = ['http://teststring', 'teststring']
      work.valid?
      expect(work.errors[:link_url]).to contain_exactly('is not a valid URL')
      expect(work.errors[:link_array]).to contain_exactly('is not a valid URL')
    end
  end
end
