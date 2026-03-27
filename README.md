Guide to randomly sample around a given point:

Example code (inside the main directory SecantsofTwoCubicsMRC2025):

First create a new directory (optional) by copying the base Bertini files. For example, use Check49 as a template:

cp -r ./Check49 ./Check1 

Next let's pick a point to sample arounnd and create a f 

python3 makecenter.py ./exParameters/parameter424 > ./Check1/currentCenter

Next we can generate a bunch of points around our point in a prescribed radious. First enter the directory, and then generate the points.

cd Check1

python3 gen.py currentCenter 0.1 100000

(in general you would run python3 gen.py centerFile radius numberToSample)

Now we can let things launch. I recommend just running the following:

bash run_bertconjsupressed.sh 100000 & 

(in general bash run_bertconjsupressed.sh numberSampled)


But we have the options: 

bash run_bertconjsupressed.sh 100000 & (if you want the process to run in the background, if you made a mistake use ps command to list processes and then kill processNumber).

bash run_bertconj3.sh 100000 (if you want to see the process run and output).

bash run_bertconjsupressedwithstart.sh 100000 (In case you have a problem where your process stops in the middle, run this; it will check the results.txt file and skip reprocessing files that have already been handled).

Output will be be continuously written into ./Check1/results.txt, to look at it (if already in the Check1 directory run)

tail results.txt (to see 10 lines)

tail -n 100 results.txt (to see the last 100 lines etc.)

If you are running it with output suppressed and you are wondering where its at you can run:

wc -l results.txt


Analysis:

In order to process the data, in the main directory you can run:

bash updateseensupressed.sh

This will go through all results.txt files in the main directory and any subdirectory and add any new triples found onto the seen.txt list


You can also run:

bash count_all_trips.sh to actually enumerate the total number of each triple that you have found. This is output to the file triple_counts.txt.

You can run:

python3 tripsvisual2.py seen.txt 

in order to visualize the triples that have been found.



You can run:

python3 sort.py 

in order to get an output file "seensort.txt" which sorts the seen.txt triples as the seen.txt file contains the found triples in the order in which they were found.


