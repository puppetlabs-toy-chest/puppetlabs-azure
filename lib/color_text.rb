module ColorText

  def colorize(text, color)
    "\e[#{color}m#{text}\e[0m"
  end

  def bold(text)
    "\e[1m#{text}"
  end

  def blue_text(text)
    colorize(text, 34)
  end

  def magenta_text(text)
    colorize(text, 35)
  end

  def yellow_text(text)
    colorize(text, 33)
  end

  def green_text(text)
    colorize(text, 32)
  end

  def red_text(text)
    colorize(text, 31)
  end

end
