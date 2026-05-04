=begin
Guide.rb

This file will provide a guide for the user to understand how to use the program efficiently.

Once the user runs the program and gets to the conflicts for a specific exercise,
the optimal way to use this program would be to find the conflicts within the exercise that has 
the least conflicts. The only problem is that isolation exercises will have to be accounted for as well.
- This means that Given CE_i -> IE_i, how do we guarantee that IE_i will not conflict with 
  CE_j where j != i?

  Note: we are using the superset architecture (CE_i to IE_i)

  To answer this, this conflict finder provides the bridge between CE_i and IE_i.
  For IE_i and CE_j, we need to have another program that finds the conflicts between 
  the isolation exercises and the compound exercises. 
  - This program will most likely use the same architecture as the conflictFinder, but
  it will use (including the CE database) the IE database. 
  Essentially, we need to have another database but for isolation exercises.
  - We already set up the muscles, so it should be easy to populate the isolation exercise DB.

  - Now, the only hurdle is finding the conflict between IE and CE.
    Isolation exercises are only going to be muscles, not part of any type of workout. 
    => The TO DO part 2 is part of this ongoing problem. 

    => We can make a contract that the user will use the Muscle Screen only when they
    are looking at whether an IE they want to do will conflict with a CE they are about to do.

      Use Case: Workout Type Screen -> Muscle Screen or Exercise Screen
        Exercise Screen initially for CE_i.
          Use the Obsidian Page for the what exercise is its specific 
            domain type (calisthenics, non-calisthenics) and the muscle targets. 
          => That will be used for the CE_i. 
        Then Muscle Screen for IE_i, to check if there is a conflict with CE_j where j != i.
            => TO DO: Database for IE muscles. Muscle Screen. 
            => This will be used for the IE_i.
        Repeat. 
        

=end
