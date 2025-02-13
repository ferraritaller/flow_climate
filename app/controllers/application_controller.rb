# frozen_string_literal: true

class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  before_action :redirect_subdomain
  before_action :set_language

  private

  def not_found
    respond_to do |format|
      format.html { render 'layouts/404', status: :not_found, layout: false }
      format.js { render plain: '404 Not Found', status: :not_found }
      format.json { render json: { errors: [{ message: 'Not found' }], data: {} }, status: :not_found }
      format.csv { render plain: '404 Not Found', status: :not_found }
    end
  end

  def redirect_subdomain
    redirect_to("https://flowclimate.com #{request.fullpath}", status: :moved_permanently) if request.host == 'www.flowclimate.com'
  end

  def page_param
    @page_param ||= params[:page] || 1
  end

  def set_language
    if current_user.blank? || current_user.language.blank?
      header_based_i18n

    else
      I18n.locale = current_user.language
    end
  end

  def header_based_i18n
    accepted_languages = request.env['HTTP_ACCEPT_LANGUAGE']
    if accepted_languages.blank?
      Rails.logger.info { "* Locale set to '#{I18n.default_locale}'" }
      I18n.locale = I18n.default_locale

    else
      Rails.logger.debug { "* Accept-Language: #{accepted_languages}" }
      locale = extract_locale_from_accept_language_header(accepted_languages)
      Rails.logger.info { "* Locale set to '#{locale}'" }
      I18n.locale = locale
    end
  end

  def extract_locale_from_accept_language_header(env_languages)
    accepted_languages = env_languages.split(',').map { |locale| locale.match('^[^\;]*')[0] }

    return 'pt-BR' if accepted_languages.include?('pt') || accepted_languages.include?('pt-BR')

    'en'
  end
end
