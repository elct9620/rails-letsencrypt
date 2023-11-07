# frozen_string_literal: true

require 'rails_helper'
require 'rails/generators/test_case'
require 'generators/lets_encrypt/register_generator'

RSpec.describe LetsEncrypt::Generators::RegisterGenerator do
  before(:all) do
    @dummy_class = Class.new(Rails::Generators::TestCase) do
      tests LetsEncrypt::Generators::RegisterGenerator
      destination Rails.root.join('tmp')
    end
    @generator = @dummy_class.new(:fake_test_case)
  end

  it do
    answers = [
      '', # In production
      '', # File path
      'Y', # Overwrite?
      'example@example.com' # E-Mail
    ]
    allow(Thor::LineEditor).to receive(:readline) { answers.shift.dup || 'N' }

    expect(LetsEncrypt).to receive(:register).and_return(true)

    @generator.send(:prepare_destination)
    @generator.run_generator
  end
end
