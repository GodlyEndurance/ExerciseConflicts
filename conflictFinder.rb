=begin
conflictFinder.rb

# Purpose
This script is used to find matching agonists and/or synergists within each exercise that is in their 
respective type of workout. 

# Architecture
The types of workouts are: core, lower, pull, and push. 
The leg and upper are excluded, because the leg is the lower body or core, which is redundant.
The upper is the push or pull, which is also redundant. 

# Input
The text files will be: core.txt, lower.txt, pull.txt, and push.txt. 

# Operations
We will have a class for each of these types of workouts, and we will have an associative array
such that we can easily refer to the muscle target of each exercise, rather than the indexes of the
array being integers. 

We will use the text files to get the exercises, and then find which ones are in conflict with each
other. To represent a conflict between 2+ exercises, we will use the muscle target as the
comparison. 

Since we have the same attributes for each class, we will make each class a subclass of the class
WorkoutType. 

WorkoutType will have the following attributes: name, exercises, and muscleTargets.

The muscleTargets will be an associative array that maps the name of the exercise to the muscle target.

There will be another class (ConflictFinder) that will be used to find the conflicts between the exercises, and it
use a database class that has ALL of the general muscles to be exercised.
  Note that the database class will not have a generator. We used AI (deepseek) to make it less redundant 
  after we generated a document that populated all of the unique muscle targets.

=end

require 'singleton'

class WorkoutType
  attr_accessor :name, :exercises, :muscle_targets

  def initialize(name)
    @name           = name
    @exercises      = []
    @muscle_targets = {}
  end
end

class Muscle
  ROLES = %i[agonist synergist antagonist stabilizer].freeze

  def initialize
    @by_role = ROLES.each_with_object({}) { |r, h| h[r] = [] }
  end

  def add_exercise(exercise_name, role)
    @by_role[role] << exercise_name unless @by_role[role].include?(exercise_name)
  end

  def exercises
    @by_role.values.flatten.uniq
  end

  def exercises_for(role)
    @by_role[role]
  end

  def conflict?
    exercises.length >= 2
  end
end

class Database
  include Singleton

  require 'rubyXL'

  DB_PATH = File.join(File.dirname(__FILE__), 'Database', 'exercises_database.xlsx')

  def muscles
    @muscles ||= begin
      sheet = RubyXL::Parser.parse(DB_PATH)['Muscles Database']
      sheet.drop(1).filter_map { |row| row&.[](0)&.value&.then { |v| v.to_s.strip.empty? ? nil : v } }
    end
  end
end

# Dynamically generate a Muscle subclass for each entry in the database.
# Class name is derived by stripping parentheticals and joining words in CamelCase.
# e.g. "Lats (Latissimus Dorsi)" => Lats, "Gluteus Medius & Minimus" => GluteusMediusMinimus
MUSCLE_REGISTRY = Database.instance.muscles.each_with_object({}) do |muscle_name, registry|
  class_name = muscle_name.gsub(/\s*\(.*?\)/, '').gsub(/[^a-zA-Z0-9\s]/, '').split.map(&:capitalize).join
  klass      = Class.new(Muscle) { const_set(:NAME, muscle_name.freeze) }
  Object.const_set(class_name, klass)
  registry[muscle_name] = klass
end.freeze

class ConflictFinder
  include Singleton

  CONFLICT_ROLES = %i[agonist synergist stabilizer].freeze

  # Returns conflicts for a single exercise vs all others in the same workout.
  # Muscles are keyed by their role in the selected exercise (antagonist excluded).
  def conflicts_for(exercise_name, workout)
    target_muscles = workout.muscle_targets[exercise_name]
    return {} unless target_muscles

    target_set = CONFLICT_ROLES.flat_map { |r| target_muscles[r] }.uniq
    results    = {}

    workout.muscle_targets.each do |other_name, other_roles|
      next if other_name == exercise_name

      other_set = CONFLICT_ROLES.flat_map { |r| other_roles[r] }.uniq
      next if (target_set & other_set).empty?

      shared_by_role = CONFLICT_ROLES.each_with_object({}) do |role, h|
        overlap = target_muscles[role].select { |m| other_set.include?(m) }
        h[role] = overlap unless overlap.empty?
      end
      results[other_name] = shared_by_role
    end

    results
  end
end

# ── Interactive UI helpers ────────────────────────────────────────────────────

require_relative 'UI/UI_Aid'
include UIAid

ROLE_LABELS = {
  agonist:   '(+) agonist',
  synergist: '(~) synergist',
  stabilizer:'(o) stabilizer'
}.freeze

WORKOUT_KEYS = %w[Core Lower Pull Push].freeze

# Parses a single workout text file and populates the workout's exercises and muscle_targets.
def parse_workout_file(path, workout, valid_muscles)
  current = nil

  IO.foreach(path) do |raw|
    line = raw.chomp
    next if line.start_with?('Form:') || line.strip.empty? || line =~ /^---/

    if line =~ /^([^|]+)\|\s*(.+)$/
      if current
        workout.exercises << current[:name]
        workout.muscle_targets[current[:name]] = current.reject { |k, _| k == :name }
      end
      current = { name: $2.strip, agonist: [], synergist: [], antagonist: [], stabilizer: [] }
      next
    end

    if current && line =~ /^\s+(Agonist|Synergist|Antagonist|Stabilizer):\s+(.+)$/i
      role          = $1.downcase.to_sym
      muscles       = $2.split(',').map(&:strip).reject { |m| m.start_with?('(') || m == '(—)' }
      current[role] = muscles.select { |m| valid_muscles.include?(m.downcase) }
    end
  end

  if current
    workout.exercises << current[:name]
    workout.muscle_targets[current[:name]] = current.reject { |k, _| k == :name }
  end
end

# Builds and returns a workout_map hash from all workout text files.
# Each type maps to { ce: WorkoutType, ie: WorkoutType }.
def inputHandler
  valid_muscles = Database.instance.muscles.map(&:downcase).to_set
  workout_map   = WORKOUT_KEYS.each_with_object({}) do |t, h|
    h[t] = { ce: WorkoutType.new("#{t} (Compound)"), ie: WorkoutType.new("#{t} (Isolation)") }
  end

  WORKOUT_KEYS.each do |type|
    base = File.join(File.dirname(__FILE__), 'Raw_Exercises')
    parse_workout_file(File.join(base, "#{type}CE.txt"), workout_map[type][:ce], valid_muscles)
    parse_workout_file(File.join(base, "#{type}IE.txt"), workout_map[type][:ie], valid_muscles)
  end

  workout_map
end

require_relative 'UI/WorkoutTypeScreen'
require_relative 'UI/WorkoutTypeCompletion'

# Main interactive loop
def main()
  workouts = inputHandler

  header("** EXERCISE CONFLICT FINDER **")
  puts "\n#{indent}Welcome! (๑>◡<๑)"
  divider

  loop do
    puts "\n#{indent(2)}1. Start"
    puts "#{indent(2)}2. Check workout completion"
    puts "#{indent(2)}0. Quit"
    choice = prompt("Choice")
    next puts "#{indent}Invalid choice." unless %w[0 1 2].include?(choice)
    break puts "\n#{indent}Goodbye! (๑>◡<๑)\n" if choice == '0'

    if choice == '2'
      WorkoutTypeCompletion.new(workouts).run
      next
    end

    WorkoutTypeScreen.new(workouts).run
    break
  end

end



main()


=begin
TO DO:
[DONE] Workout Type Screen -> Exercise Screen or Isolation Screen
  Exercise Screen: shows conflicts / non-conflicts for a selected exercise.
  Isolation Screen: shows all exercises in the workout that target a selected muscle.

[DONE] After viewing results (either screen), prompt to save the exercise or muscle
  to PossibleWorkout.txt. Entries are grouped by workout type in that file
  (e.g. all Pull entries together, then all Push entries, etc.).

=end