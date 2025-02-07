# frozen_string_literal: true

# DUL CUSTOM COMPONENT. Render an iframe for an embeddable DDR object
class DigitalObjectDdrEmbedComponent < ViewComponent::Base
  def initialize(object:)
    super

    @object = object
  end

  def iframe_height
    case @object.role
    when 'audio-streaming'
      '125px'
    when 'image-service'
      '600px'
    else
      '500px'
    end
  end

  def iframe_title
    case @object.role
    when 'audio-streaming'
      'Embedded audio player'
    when 'image-service'
      'Embedded image viewer'
    when 'video-streaming'
      'Embedded video player'
    else
      'Embedded object viewer'
    end
  end
end
