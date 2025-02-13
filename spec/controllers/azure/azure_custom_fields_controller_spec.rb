# frozen_string_literal: true

RSpec.describe Azure::AzureCustomFieldsController do
  context 'unauthenticated' do
    describe 'POST #create' do
      before { post :create, params: { company_id: 'foo', azure_account_id: 'bar' } }

      it { expect(response).to redirect_to new_user_session_path }
    end

    describe 'DELETE #destroy' do
      before { delete :destroy, params: { company_id: 'foo', id: 'bar' } }

      it { expect(response).to redirect_to new_user_session_path }
    end
  end

  context 'authenticated' do
    let(:user) { Fabricate :user }
    before { sign_in user }

    let(:company) { Fabricate :company, users: [user] }

    describe 'POST #create' do
      let!(:azure_account) { Fabricate :azure_account, company: company }

      context 'with valid parameters' do
        it 'creates the new azure custom field' do
          post :create, params: { company_id: company, azure_account_id: azure_account, azure_azure_custom_field: { custom_field_type: :team_name, custom_field_name: 'xpto', field_order: 1 } }, xhr: true

          created_custom = Azure::AzureCustomField.last

          expect(created_custom.custom_field_name).to eq 'xpto'
          expect(created_custom.custom_field_type).to eq 'team_name'
          expect(created_custom.field_order).to eq 1
          expect(assigns(:new_azure_custom_field)).to be_a_new Azure::AzureCustomField
          expect(response).to render_template 'azure/azure_custom_fields/create'
        end
      end

      context 'invalid' do
        context 'invalid paramters' do
          it 're-renders the form with the errors' do
            post :create, params: { company_id: company, azure_account_id: azure_account, azure_azure_custom_field: { custom_field_type: :team_name, custom_field_name: '' } }, xhr: true

            expect(assigns(:new_azure_custom_field).errors.full_messages).to eq ['Nome de Máquina do Campo não pode ficar em branco']
          end
        end

        context 'company' do
          context 'non-existent' do
            before { post :create, params: { company_id: 'foo', azure_account_id: azure_account } }

            it { expect(response).to have_http_status :not_found }
          end

          context 'not-permitted' do
            let(:company) { Fabricate :company, users: [] }
            let!(:azure_account) { Fabricate :azure_account, company: company }

            before { post :create, params: { company_id: company, azure_account_id: azure_account } }

            it { expect(response).to have_http_status :not_found }
          end
        end
      end
    end

    describe 'DELETE #destroy' do
      context 'with valid parameters' do
        it 'deletes the custom field' do
          azure_account = Fabricate :azure_account, company: company
          custom_field = Fabricate :azure_custom_field, azure_account: azure_account

          delete :destroy, params: { company_id: company, id: custom_field }, xhr: true

          expect(Azure::AzureCustomField.all.count).to eq 0
          expect(response).to render_template 'azure/azure_custom_fields/destroy'
        end
      end

      context 'with invalid' do
        context 'non-existent company' do
          let(:azure_account) { Fabricate :azure_account, company: company }
          let(:custom_field) { Fabricate :azure_custom_field, azure_account: azure_account }

          before { delete :destroy, params: { company_id: 'foo', id: custom_field }, xhr: true }

          it { expect(response).to have_http_status :not_found }
        end

        context 'custom field for another company' do
          let!(:azure_account) { Fabricate :azure_account, company: company }

          let(:other_company) { Fabricate :company }
          let(:other_azure_account) { Fabricate :azure_account, company: other_company }
          let!(:custom_field) { Fabricate :azure_custom_field, azure_account: other_azure_account }

          before { delete :destroy, params: { company_id: company, id: custom_field }, xhr: true }

          it { expect(response).to have_http_status :not_found }
        end

        context 'inexistent custom field' do
          let!(:azure_account) { Fabricate :azure_account, company: company }
          let!(:custom_field) { Fabricate :azure_custom_field, azure_account: azure_account }

          before { delete :destroy, params: { company_id: company, id: 'foo' }, xhr: true }

          it { expect(response).to have_http_status :not_found }
        end
      end
    end
  end
end
