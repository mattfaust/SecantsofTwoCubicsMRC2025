import sys
import os

with open("nonsingular_solutions") as f:
    lines = [line.strip() for line in f if line.strip()]

lines = lines[1:len(lines)]
realpart = []
complexpart = []
for i in lines:
    numlist = i.split(" ")
    realpart.append(float(numlist[0]))
    complexpart.append(float(numlist[1]))

total_blocks = len(lines) // 6

A = []
B = []
T1 = []
T2 = []
for i in range(total_blocks):
    block_start = i * 6
    A.append(realpart[block_start])
    B.append(realpart[block_start + 1])
    T1.append(realpart[block_start+4])
    T2.append(realpart[block_start + 5])
print(str(A))
print(str(B))
print(str(T1))
print(str(T2))


