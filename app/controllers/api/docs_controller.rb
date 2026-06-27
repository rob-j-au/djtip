# frozen_string_literal: true

module Api
  class DocsController < ApplicationController
    layout false

    def index
      render :index
    end
  end
end
