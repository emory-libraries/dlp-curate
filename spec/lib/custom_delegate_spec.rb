# frozen_string_literal: true
require 'rails_helper'
require 'custom_delegate'

RSpec.describe CustomDelegate do
  subject(:delegate) { described_class.new }

  context '#s3source_object_info' do
    describe 'when given a Fedora 7 OCFL identifier' do
      let(:uuid) { '18aa1b37-5fb5-42e2-a140-d8b0dfb559ac' }
      let(:expected_sha256_original) do
        'f01ca7cc6f7cb1dfe54a0ba82e9aefb2e0aa9ac2ded98368ea78794dc134ac74'
      end
      let(:expected_sha256_service) do
        'f87d4250f159cc7c304075e4c62f64d07c1361c9dfa49ee06b020d92f1d96992'
      end
      let(:expected_sha256_intermediate) do
        'b981d8aa95bb801a8bc5512166b2a4bdc7d87d0ca46557bbad15a0f50fd7c930'
      end

      it "maps original filetype to the key with the right sha256" do
        delegate.context = { 'identifier' => "fedora7--original--#{uuid}" }

        expect(delegate.s3source_object_info).to include(
          'bucket' => 'dlp-fedora-*-binaries',
          'access_key_id' => '**secret2**',
          'secret_access_key' => '**secret3**',
          'key' => "f01/ca7/cc6/#{expected_sha256_original}/v1/content/original"
        )
      end

      it "maps service filetype to the key with the right sha256" do
        delegate.context = { 'identifier' => "fedora7--service--#{uuid}" }

        expect(delegate.s3source_object_info).to include(
          'bucket' => 'dlp-fedora-*-binaries',
          'access_key_id' => '**secret2**',
          'secret_access_key' => '**secret3**',
          'key' => "f87/d42/50f/#{expected_sha256_service}/v1/content/service"
        )
      end

      it "maps intermediate filetype to the key with the right sha256" do
        delegate.context = { 'identifier' => "fedora7--intermediate--#{uuid}" }

        expect(delegate.s3source_object_info).to include(
          'bucket' => 'dlp-fedora-*-binaries',
          'access_key_id' => '**secret2**',
          'secret_access_key' => '**secret3**',
          'key' => "b98/1d8/aa9/#{expected_sha256_intermediate}/v1/content/intermediate"
        )
      end
    end

    context 'when given a legacy Fedora 4 SHA-1 identifier' do
      let(:sha1) { '3eee65dff00c81269ff49ac9fdf8cdf46bf9f88c' }

      it 'routes to fedora-cor-test-binaries with the SHA-1 as the S3 key' do
        delegate.context = { 'identifier' => sha1 }

        expect(delegate.s3source_object_info).to include(
          'bucket' => 'fedora-cor-*-binaries',
          'access_key_id' => '**secret1**',
          'secret_access_key' => '**secret**',
          'key' => sha1
        )
      end
    end

    context 'when given invalid or malformed identifiers' do
      [
        nil,
        '',
        'fedora7--thumbnail--18aa1b37-5fb5-42e2-a140-d8b0dfb559ac',
        'fedora7--original--not-a-uuid',
        'fedora7--original--18aa1b37-5fb5-42e2-a140-d8b0dfb559ac--extra',
        'fedora4--3eee65dff00c81269ff49ac9fdf8cdf46bf9f88c'
      ].each do |invalid_id|
        it "returns nil for #{invalid_id.inspect}" do
          delegate.context = { 'identifier' => invalid_id }

          expect(delegate.s3source_object_info).to be_nil
        end
      end
    end
  end
end
