require_relative 'UI_Aid'

# Handles muscle selection (filtered by workout type) and displays
# which exercises in that workout target the selected muscle.
class IsolationScreen
  include UIAid

  MUSCLES_BY_TYPE = {
    'Push'  => [
      'Anterior Deltoid', 'Medial Deltoid', 'Pectoralis Major',
      'Serratus Anterior', 'Triceps Brachii'
    ],
    'Pull'  => [
      'Biceps Brachii', 'Brachialis', 'Brachioradialis',
      'Forearm Flexors (Grip)', 'Lats (Latissimus Dorsi)',
      'Lower Traps', 'Middle Traps', 'Posterior Deltoid',
      'Rhomboids', 'Rotator Cuff', 'Teres Major', 'Upper Traps'
    ],
    'Lower' => [
      'Adductors', 'Erector Spinae', 'Gastrocnemius', 'Gluteus Maximus',
      'Gluteus Medius & Minimus', 'Hamstrings', 'Quadriceps', 'Soleus'
    ],
    'Core'  => [
      'Hip Flexors', 'Obliques', 'Rectus Abdominis'
    ]
  }.freeze

  SEARCH_ROLES = %i[agonist].freeze

  def initialize(type, workout)
    @type    = type
    @workout = workout
    @muscles = MUSCLES_BY_TYPE[@type] || []
  end

  # Runs the isolation muscle loop. Returns :back_to_types or :quit.
  def run
    loop do
      box("#{@type.upcase} -- SELECT MUSCLE")
      sent        = saved_entries(@type)
      muscle_opts = @muscles.each_with_index.to_h do |m, i|
        exercises   = exercises_for_muscle(m)
        label = if !exercises.empty? && exercises.any? { |ex| sent.include?("#{ex} (Isolation)") }
                  "#{m}  (SENT)"
                elsif exercises.empty?
                  "#{m}  (EMPTY)"
                else
                  m
                end
        [i + 1, label]
      end
      next_key  = (muscle_opts.keys.max || 0) + 1
      nav_opts  = muscle_opts.merge(
        next_key     => "-- Switch to Exercise Screen (#{@type})",
        next_key + 1 => "-- Back to screen select (#{@type})",
        next_key + 2 => "-- Different workout type",
        next_key + 3 => "-- Check workout type completion"
      )
      choice = ask(nav_opts)
      return :quit if choice == 0
      return :switch_to_exercise     if choice == next_key
      return :back_to_screen_select   if choice == next_key + 1
      return :back_to_types           if choice == next_key + 2
      return :check_completion        if choice == next_key + 3

      muscle_name = muscle_opts[choice].sub(/  \((SENT|EMPTY)\)$/, '')
      result = pick_exercise(muscle_name)
      case result
      when :quit                  then return :quit
      when :change_type           then return :back_to_types
      when :switch_to_exercise    then return :switch_to_exercise
      when :back_to_screen_select then return :back_to_screen_select
      when :check_completion      then return :check_completion
      # :back_to_muscles => continue muscle loop
      end
    end
  end

  private

  def has_exercises?(muscle_name)
    @workout.muscle_targets.any? do |_exercise, roles|
      roles[:agonist]&.any? { |m| m.casecmp(muscle_name).zero? }
    end
  end

  def exercises_for_muscle(muscle_name)
    @workout.muscle_targets.each_with_object([]) do |(exercise, roles), arr|
      SEARCH_ROLES.each do |role|
        if roles[role]&.any? { |m| m.casecmp(muscle_name).zero? }
          arr << exercise unless arr.include?(exercise)
        end
      end
    end
  end

  # Shows exercises for the muscle as a selectable list; lets the user
  # pick one to save, then prompts next action. Returns a signal symbol.
  def pick_exercise(muscle_name)
    sent = saved_entries(@type)
    found = {}
    @workout.muscle_targets.each do |exercise, roles|
      SEARCH_ROLES.each do |role|
        if roles[role]&.any? { |m| m.casecmp(muscle_name).zero? }
          (found[exercise] ||= []) << role
        end
      end
    end

    box("#{@type.upcase} -- #{muscle_name.upcase}")

    if found.empty?
      puts "\n#{indent}No exercises found targeting \"#{muscle_name}\" in #{@type}."
      divider
      return :back_to_muscles
    end

    ex_opts = found.keys.each_with_index.to_h do |ex, i|
      label = sent.include?("#{ex} (Isolation)") ? "#{ex}  (SENT)" : ex
      [i + 1, label]
    end
    next_key = (ex_opts.keys.max || 0) + 1
    nav_opts = ex_opts.merge(
      next_key     => "-- Back to muscle select",
      next_key + 1 => "-- Switch to Exercise Screen (#{@type})",
      next_key + 2 => "-- Back to screen select (#{@type})",
      next_key + 3 => "-- Different workout type",
      next_key + 4 => "-- Check workout type completion"
    )

    loop do
      ex_choice = ask(nav_opts)
      return :quit               if ex_choice == 0
      return :back_to_muscles    if ex_choice == next_key
      return :switch_to_exercise if ex_choice == next_key + 1
      return :back_to_screen_select if ex_choice == next_key + 2
      return :back_to_types      if ex_choice == next_key + 3
      return :check_completion   if ex_choice == next_key + 4

      raw_name = ex_opts[ex_choice].sub(/  \(SENT\)$/, '')
      save_entry(@type, 'Isolation', raw_name) if yes_no("Save \"#{raw_name}\" to PossibleWorkout.txt?")
      # refresh SENT labels after possible save
      sent    = saved_entries(@type)
      ex_opts = found.keys.each_with_index.to_h do |ex, i|
        label = sent.include?("#{ex} (Isolation)") ? "#{ex}  (SENT)" : ex
        [i + 1, label]
      end
      nav_opts = ex_opts.merge(
        next_key     => "-- Back to muscle select",
        next_key + 1 => "-- Switch to Exercise Screen (#{@type})",
        next_key + 2 => "-- Back to screen select (#{@type})",
        next_key + 3 => "-- Different workout type",
        next_key + 4 => "-- Check workout type completion"
      )
    end
  end

  def show_exercises(muscle_name)
    header("EXERCISES FOR: #{muscle_name}")

    found = {}
    @workout.muscle_targets.each do |exercise, roles|
      SEARCH_ROLES.each do |role|
        if roles[role]&.any? { |m| m.casecmp(muscle_name).zero? }
          (found[exercise] ||= []) << role
        end
      end
    end

    if found.empty?
      puts "\n#{indent}No exercises found targeting \"#{muscle_name}\" in #{@type}."
    else
      found.each do |exercise, roles|
        puts "\n#{indent}◈ #{exercise}"
        divider('·')
        roles.each { |r| puts "#{indent(2)}#{ROLE_LABELS[r]}" }
      end
    end

    divider
  end

end
