# encoding: utf-8
require 'rails_email_preview/engine'
require 'rails_email_preview/main_app_route_delegator'
require 'rails_email_preview/version'
require 'rails_email_preview/delivery_handler'
require 'rails_email_preview/view_hooks'

require 'slim'
require 'slim-rails'
require 'sass'
require 'sass-rails'
require 'request_store'

module RailsEmailPreview

  mattr_accessor :parent_controller
  self.parent_controller = '::ApplicationController'

  # preview class names
  mattr_accessor :preview_classes

  # UI locale
  mattr_accessor :locale

  # default email locale
  mattr_accessor :default_email_locale

  # send email button
  mattr_accessor :enable_send_email
  self.enable_send_email = true

  # some easy visual settings
  mattr_accessor :style
  self.style = {
      btn_default_class:     'btn btn-default',
      btn_active_class:      'btn btn-primary active',
      btn_group_class:       'btn-group btn-group-sm',
      list_group_class:      'list-group',
      list_group_item_class: 'list-group-item',
      panel_class:           'panel panel-default',
      panel_body_class:      'panel-body',
      row_class:             'row',
      column_class:          'col-sm-%{n}'
  }

  @view_hooks = RailsEmailPreview::ViewHooks.new
  class << self
    # @return [RailsEmailPreview::ViewHooks]
    attr_reader :view_hooks
    def preview_classes=(classes)
      @preview_classes = classes
      RailsEmailPreview::Preview.load_all(classes)
    end

    def layout=(layout)
      [::RailsEmailPreview::ApplicationController, ::RailsEmailPreview::EmailsController].each { |ctrl| ctrl.layout layout }
      if layout && layout !~ %r(^rails_email_preview/)
        # inline application routes if using an app layout
        inline_main_app_routes!
      end
    end

    def run_before_render(mail, preview)
      (defined?(@hooks) && @hooks[:before_render] || []).each do |block|
        block.call(mail, preview)
      end
    end

    def before_render(&block)
      ((@hooks ||= {})[:before_render] ||= []) << block
    end

    def inline_main_app_routes!
      unless ::RailsEmailPreview::EmailsController.instance_variable_get(:@inlined_routes)
        ::RailsEmailPreview::EmailsController.helper ::RailsEmailPreview::MainAppRouteDelegator
        ::RailsEmailPreview::EmailsController.instance_variable_set(:@inlined_routes, true)
      end
    end

    def setup
      yield self
    end
  end

  # = Editing settings
  # edit link is rendered inside an iframe, so these options are provided for simple styling
  mattr_accessor :edit_link_text
  self.edit_link_text = '✎ Edit Text'
  mattr_accessor :edit_link_style
  self.edit_link_style = <<-CSS.strip.gsub(/\n+/m, ' ')
  display: block;
  font-family: Monaco, Helvetica, sans-serif;
  color: #7a4b8a;
  border: 2px dashed #7a4b8a;
  font-size: 20px;
  padding: 8px 12px;
  margin-top: 0.6em;
  margin-bottom: 0.6em;
  CSS
end
