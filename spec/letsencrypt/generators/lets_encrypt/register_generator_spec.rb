# frozen_string_literal: true

require 'rails_helper'
require 'rails/generators/test_case'
require 'generators/lets_encrypt/register_generator'

RSpec.describe LetsEncrypt::Generators::RegisterGenerator do
  let(:klass) do
    Class.new(Rails::Generators::TestCase) do
      tests LetsEncrypt::Generators::RegisterGenerator
      destination Rails.root.join('tmp')
    end
  end

  let(:generator) { klass.new(:fake_test_case) }

  before do
    answers = [
      '', # In production
      '', # File path
      'Y', # Overwrite?
      'example@example.com' # E-Mail
    ]
    allow(Thor::LineEditor).to receive(:readline) { answers.shift.dup || 'N' }
    allow(LetsEncrypt).to receive(:register).and_return(true)

    generator.send(:prepare_destination)
    generator.run_generator
  end

  it { expect(LetsEncrypt).to have_received(:register).with('example@example.com') }
end
