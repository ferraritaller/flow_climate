# frozen_string_literal: true

module Jira
  class JiraReader
    include Singleton

    def read_project(jira_issue_attrs, jira_account)
      projects_names = read_project_name(jira_issue_attrs)

      jira_product_key = read_product_jira_key(jira_issue_attrs)
      jira_product = jira_account.company.jira_product_configs.where(jira_product_key: jira_product_key).first
      return if jira_product.blank?

      jira_config = nil
      projects_names.each do |project_name|
        jira_config = jira_product.jira_project_configs.find_by(fix_version_name: project_name)
        break if jira_config.present?
      end

      return if jira_config.blank?

      jira_config.project
    end

    def read_product(jira_issue_attrs, jira_account)
      jira_product_key = read_product_jira_key(jira_issue_attrs)
      jira_product = jira_account.company.jira_product_configs.where(jira_product_key: jira_product_key).first
      return if jira_product.blank?

      jira_product.product
    end

    def read_customer(jira_account, jira_issue_attrs)
      customer_custom_field_name = jira_account.customer_custom_field&.custom_field_machine_name

      jira_custom_fields_hash = build_jira_custom_fields_hash(jira_issue_attrs)

      customer_name = jira_custom_fields_hash[customer_custom_field_name]

      jira_account.company.customers.find_by(name: extract_customer_name(customer_name)) if customer_name.present?
    end

    def read_contract(jira_account, jira_issue_attrs)
      contract_custom_field_name = jira_account.contract_custom_field&.custom_field_machine_name

      jira_custom_fields_hash = build_jira_custom_fields_hash(jira_issue_attrs)

      contract_id = if jira_custom_fields_hash[contract_custom_field_name].is_a?(Array)
                      jira_custom_fields_hash[contract_custom_field_name].try(:[], 0)
                    else
                      jira_custom_fields_hash[contract_custom_field_name]
                    end

      jira_account.company.contracts.find_by(id: contract_id) if contract_id.present?
    end

    def read_demand_key(jira_issue_attrs)
      jira_issue_attrs['key']
    end

    def read_project_url(jira_issue_attrs)
      jira_issue_attrs['fields']['project']['self']
    end

    def read_class_of_service(demand, jira_account, jira_issue_attrs, jira_issue_changelog)
      class_of_service_name = read_class_of_service_by_field_name(demand, jira_issue_changelog)

      class_of_service_name = read_class_of_service_by_custom_field_id(demand, jira_account, jira_issue_attrs) if class_of_service_name.blank?

      if class_of_service_name.casecmp('expedite').zero?
        :expedite
      elsif class_of_service_name.casecmp('fixed date').zero?
        :fixed_date
      elsif class_of_service_name.casecmp('intangible').zero?
        :intangible
      else
        :standard
      end
    end

    private

    def extract_customer_name(customer_name)
      if customer_name.is_a?(Array)
        customer_name[0]['value']
      else
        customer_name['value']
      end
    end

    def read_project_name(jira_issue_attrs)
      labels = jira_issue_attrs['fields']['labels'] || []
      fix_version_name = read_fix_version_name(jira_issue_attrs)

      labels << fix_version_name
      labels.compact_blank
    end

    def read_fix_version_name(jira_issue_attrs)
      return '' if jira_issue_attrs['fields']['fixVersions'].blank?

      jira_issue_attrs['fields']['fixVersions'][0]['name']
    end

    def read_product_jira_key(jira_issue_attrs)
      jira_issue_attrs['fields']['project']['key']
    end

    def read_class_of_service_by_custom_field_id(demand, jira_account, jira_issue_attrs)
      class_of_service_custom_field_name = jira_account.class_of_service_custom_field&.custom_field_machine_name

      jira_custom_fields_hash = build_jira_custom_fields_hash(jira_issue_attrs)

      if class_of_service_custom_field_name.blank?
        class_of_service_name = 'standard'
      else
        class_of_service_hash = jira_custom_fields_hash[class_of_service_custom_field_name]

        class_of_service_name = if class_of_service_hash.blank?
                                  'standard'
                                else
                                  class_of_service_hash['value']
                                end
      end
      create_history_for_class_of_service_changing(demand, demand.created_date, nil, class_of_service_name)

      class_of_service_name
    end

    def read_class_of_service_by_field_name(demand, jira_issue_changelog)
      class_of_service = ''
      return class_of_service if jira_issue_changelog.blank?

      jira_issue_changelog['histories'].sort_by { |history_hash| history_hash['created'] }.each do |history|
        next unless history['items'].present? && class_of_service_field?(history)

        class_of_service = history['items'].first['toString']
        create_history_for_class_of_service_changing(demand, history['created'], history['items'].first['fromString'], class_of_service)
      end

      class_of_service
    end

    def class_of_service_field?(history)
      (history['items'].first['field'].downcase.include?('class of service') || history['items'].first['field'].downcase.include?('classe de serviço'))
    end

    def build_jira_custom_fields_hash(jira_issue_attrs)
      jira_issue_attrs['fields'].select { |field| field.start_with?('customfield') }
    end

    def create_history_for_class_of_service_changing(demand, change_date, from_class, to_class)
      return if from_class.blank? || to_class.blank?

      from_class_id = Demand.class_of_services[read_class_of_service_string(from_class)]
      to_class_id = Demand.class_of_services[read_class_of_service_string(to_class.downcase)]

      cos_change = History::ClassOfServiceChangeHistory.where(demand: demand, change_date: change_date, from_class_of_service: from_class_id, to_class_of_service: to_class_id).first_or_initialize
      demand.class_of_service_change_histories << cos_change
    end

    def read_class_of_service_string(class_of_service_string)
      class_of_service = class_of_service_string.downcase

      class_of_service = 'standard' if class_of_service == 'default'

      class_of_service.strip.sub(' ', '_')
    end
  end
end
