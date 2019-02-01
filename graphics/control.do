# set the working dir, where all compiled verilog goes
vlib work

# compile all verilog modules in mux.v to working dir
# could also have multiple verilog files
vlog control.v
vlog drawFSMs.v
vlog drawScreen.v
vlog drawImage.v
vlog drawMoney.v
vlog drawAction.v
vlog ../resources/ROMS/playingCards.v
vlog ../resources/ROMS/cardBack.v
vlog ../resources/ROMS/menuBG.v
vlog ../resources/ROMS/menu.v
vlog ../resources/ROMS/cursor.v
vlog ../resources/ROMS/winnerName.v
vlog ../resources/ROMS/numbers.v
vlog ../resources/
vlog ../logic/deal.v
vlog ../logic/sort.v
vlog ../logic/divider.v
vlog ../logic/moneyManager.v
vlog ../logic/computerAction.v
vlog ../logic/odds.v

#load top level simulation module
vsim -L altera_mf_ver -L 220model_ver control

# log all signals and add some signals to waveform window
log {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}

#clock
force {clock} 0 0ns, 1 {10ns} -r 20ns

# reset
force {resetn} 0 0 ns, 1 {25ns}
force {left} 0
force {right} 0

# test if winID works
force {go} 0 0ns, 1 {70ns}
force {go} 0 90ns
#run simulation for a few ns
run 5ms

force {go} 0 0ns, 1 {50ns}
force {go} 0 70ns
run 5ms

force {go} 0 0ns, 1 {50ns}
force {go} 0 70ns
run 5ms

force {go} 0 0ns, 1 {50ns}
force {go} 0 70ns
run 5ms

force {go} 0 0ns, 1 {50ns}
force {go} 0 70ns
run 5ms

force {go} 0 0ns, 1 {50ns}
force {go} 0 70ns
run 5ms

force {go} 0 0ns, 1 {50ns}
force {go} 0 70ns
run 5ms

force {right} 0 0ns, 1 {50ns}
force {right} 0 70ns
run 5ms

force {go} 0 0ns, 1 {50ns}
force {go} 0 70ns
run 5ms
