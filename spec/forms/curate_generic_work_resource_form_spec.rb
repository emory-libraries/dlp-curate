# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CurateGenericWorkResourceForm do
  subject(:form) { described_class.new(CurateGenericWorkResource.new) }

  describe '#rendering_ids=' do
    # The Rendering multi-select always posts a blank value alongside the selection.
    it 'drops the blank value the multi-select submits' do
      form.validate('rendering_ids' => ['', 'fs-pdf', 'fs-ocr'])

      expect(form.rendering_ids).to eq ['fs-pdf', 'fs-ocr']
    end

    it 'clears the renderings when nothing is selected' do
      form.validate('rendering_ids' => [''])

      expect(form.rendering_ids).to eq []
    end

    it 'carries the selection onto the work when synced' do
      form.validate('rendering_ids' => ['', 'fs-pdf'])

      expect(form.sync.rendering_ids.map(&:to_s)).to eq ['fs-pdf']
    end
  end
end
