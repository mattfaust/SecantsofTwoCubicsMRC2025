oldtrips = []
with open('seen.txt') as f:
    oldtrips = [line.strip() for line in f if line.strip()]
oldtrips.sort()
with open('seensort.txt', 'a') as file:
    for i in oldtrips:
        file.write(str(i)+'\n')

