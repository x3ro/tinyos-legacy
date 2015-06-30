functions = {}
sim.resume()
execfile("/root/src/broken/experimental/demmer/scripts/randomwalk.py")
for n in range(0, 30):
  comm.turnMoteOn(n, 21*n)
  motes[n].moveTo(50, 50)

for n in range(0, 30):
  random_walk(n, 400000, 1)


