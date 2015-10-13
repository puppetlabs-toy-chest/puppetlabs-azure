require_relative 'color_text'

module EnvVar

  include ColorText

  @@vars = []
  @@env = Struct.new(:name, :message, :default_value)

  def check_env_vars
    required_vars = []
    @@vars.each do |v|
      if v.default_value
        # check if set then set default if no value present
        yellow = yellow_text("WARNING: the variable #{v.name} is not set, proceeding with default value: ")
        green = green_text(v.default_value)
        puts yellow << green
        set_default_value(v)
      else
        # var is required
        # ad var to required_vars array if no value is set
        required_vars.push(v) unless ENV[v.name]
      end
    end
    abort_message = 'Aborting Rake:'
    required_vars.each{ |v| abort_message << red_text("\nThe environment variable ") << bold(red_text("#{v.name}")) << red_text(" is required. ") << magenta_text("#{v.message}")}

    if ! required_vars.empty? then
      puts red_text('Configuration verification failed => ') << bold(red_text('Acceptance is NOT OK to invoke'))
      abort(abort_message)
    end
    puts green_text('Configuration verified => ') << bold(green_text('Acceptance is OK to invoke'))
  end

  def set_default_value(var)
    ENV[var.name] = var.default_value
  end

  def track_env_var(var, message, required=false)
    @@vars.push(@@env.new(var, message, required))
  end

end
