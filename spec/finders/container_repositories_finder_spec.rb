# frozen_string_literal: true

require 'spec_helper'

describe ContainerRepositoriesFinder do
  let_it_be(:reporter) { create(:user) }
  let_it_be(:guest) { create(:user) }

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:project_repository) { create(:container_repository, name: 'my_image', project: project) }
  let(:params) { {} }

  before do
    group.add_reporter(reporter)
    project.add_reporter(reporter)
  end

  shared_examples 'with name search' do
    let_it_be(:not_searched_repository) do
      create(:container_repository, name: 'foo_bar_baz', project: project)
    end

    %w[my_image my_imag _image _imag].each do |name|
      context "with name set to #{name}" do
        let(:params) { { name: name } }

        it { is_expected.to contain_exactly(project_repository)}

        it { is_expected.not_to include(not_searched_repository)}
      end
    end
  end

  describe '#execute' do
    context 'with authorized user' do
      subject { described_class.new(user: reporter, subject: subject_object, params: params).execute }

      context 'when subject_type is group' do
        let(:subject_object) { group }
        let(:other_project) { create(:project, group: group) }

        let(:other_repository) do
          create(:container_repository, name: 'test_repository2', project: other_project)
        end

        it { is_expected.to match_array([project_repository, other_repository]) }

        it_behaves_like 'with name search'
      end

      context 'when subject_type is project' do
        let(:subject_object) { project }

        it { is_expected.to match_array([project_repository]) }

        it_behaves_like 'with name search'
      end

      context 'with invalid subject_type' do
        let(:subject_object) { "invalid type" }

        it { expect { subject }.to raise_exception('invalid subject_type') }
      end
    end

    context 'with unauthorized user' do
      subject { described_class.new(user: guest, subject: group).execute }

      it { is_expected.to be nil }
    end
  end
end
