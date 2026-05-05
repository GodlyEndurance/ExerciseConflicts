require_relative 'UI_Aid'
require_relative 'IsolationScreen'

# Checks PossibleWorkout.txt and reports which muscles in each workout type
# have been covered (as agonist or synergist) by the saved exercises/muscles,
# and which are still missing.
class WorkoutTypeCompletion
  include UIAid

  COVERAGE_ROLES = %i[agonist synergist stabilizer].freeze

  def initialize(workouts)
    @workouts = workouts  # { 'Push' => { ce: WorkoutType, ie: WorkoutType }, ... }
  end

  def run
    unless File.exist?(OUTPUT_PATH)
      header("WORKOUT TYPE COMPLETION")
      puts "\n#{indent}No PossibleWorkout.txt found — nothing saved yet."
      divider
      return
    end

    sections = parse_output_file

    header("WORKOUT TYPE COMPLETION")

    WORKOUT_KEYS.each do |type|
      covered = covered_muscles(type, sections[type] || [])
      required = IsolationScreen::MUSCLES_BY_TYPE[type] || []

      done    = required.select { |m| covered.any? { |c| c.casecmp(m).zero? } }
      missing = required.reject { |m| covered.any? { |c| c.casecmp(m).zero? } }

      puts "\n#{'─' * (WIDTH - 4)}"
      puts "#{indent}#{type.upcase}"
      puts "#{'─' * (WIDTH - 4)}"

      if missing.empty?
        puts "#{indent(2)}All muscles covered! (๑>◡<๑)"
      else
        puts "#{indent(2)}Covered (#{done.length}/#{required.length}):"
        done.each    { |m| puts "#{indent(4)}[x]  #{m}" }
        puts "#{indent(2)}Missing (#{missing.length}/#{required.length}):"
        missing.each { |m| puts "#{indent(4)}[ ]  #{m}" }
      end
    end

    divider
  end

  private

  # Returns a hash { type => [raw_entry, ...] } from PossibleWorkout.txt
  def parse_output_file
    sections        = Hash.new { |h, k| h[k] = [] }
    current_section = nil
    File.foreach(OUTPUT_PATH) do |line|
      line = line.chomp
      if line =~ /^=== (.+) ===/
        current_section = $1
      elsif current_section && !line.strip.empty?
        sections[current_section] << line
      end
    end
    sections
  end

  # Given saved entries for a type, collect every muscle that appears as
  # agonist or synergist across all referenced exercises/muscles.
  def covered_muscles(type, entries)
    covered = []
    ce      = @workouts[type][:ce]
    ie      = @workouts[type][:ie]

    entries.each do |entry|
      if entry =~ /^(.+) \(Exercise\)$/
        name    = $1
        targets = ce.muscle_targets[name] || ie.muscle_targets[name]
        next unless targets
        COVERAGE_ROLES.each { |r| covered.concat(targets[r] || []) }

      elsif entry =~ /^(.+) \(Isolation\)$/
        name    = $1
        targets = ie.muscle_targets[name] || ce.muscle_targets[name]
        next unless targets
        COVERAGE_ROLES.each { |r| covered.concat(targets[r] || []) }

      elsif entry =~ /^(.+) \(Muscle\)$/
        covered << $1
      end
    end

    covered.uniq
  end
end
