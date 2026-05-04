require 'rubyXL'
require 'rubyXL/convenience_methods'

# Curated muscle target list
MUSCLES = [
  'Adductors',
  'Anterior Deltoid',
  'Biceps Brachii',
  'Brachialis',
  'Brachioradialis',
  'Erector Spinae',
  'Forearm Flexors (Grip)',
  'Gastrocnemius',
  'Gluteus Maximus',
  'Gluteus Medius & Minimus',
  'Hamstrings',
  'Hip Flexors',
  'Lats (Latissimus Dorsi)',
  'Lower Traps',
  'Medial Deltoid',
  'Middle Traps',
  'Obliques',
  'Pectoralis Major',
  'Posterior Deltoid',
  'Quadriceps',
  'Rectus Abdominis',
  'Rhomboids',
  'Rotator Cuff',
  'Serratus Anterior',
  'Teres Major',
  'Triceps Brachii',
  'Upper Traps'
].freeze

workbook         = RubyXL::Workbook.new
sheet            = workbook[0]
sheet.sheet_name = 'Muscles Database'

sheet.add_cell(0, 0, 'Muscle Target')

MUSCLES.each_with_index do |muscle, row|
  sheet.add_cell(row + 1, 0, muscle)
end

output_path = File.join(File.dirname(__FILE__), 'exercises_database.xlsx')
workbook.write(output_path)
puts "Workbook written to #{output_path}"
