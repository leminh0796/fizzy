module BubblesHelper
  BUBBLE_ROTATION = %w[ 75 60 45 35 25 5 ]

  def bubble_title(bubble)
    bubble.title.presence || "Untitled"
  end

  def bubble_rotation(bubble)
    value = BUBBLE_ROTATION[Zlib.crc32(bubble.to_param) % BUBBLE_ROTATION.size]

    "--bubble-rotate: #{value}deg;"
  end
end
