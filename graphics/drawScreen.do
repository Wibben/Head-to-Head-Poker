# set the working dir, where all compiled verilog goes
vlib work

# compile all verilog modules in mux.v to working dir
# could also have multiple verilog files
vlog drawScreen.v
vlog drawImage.v
vlog playingCards.v
vlog cardBack.v
vlog background.v
vlog menu.v
vlog cursor.v

#load top level simulation module
vsim -L altera_mf_ver drawScreen

# log all signals and add some signals to waveform window
log {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}

#clock
force {clock} 0 0ns, 1 {10ns} -r 20ns

# reset
force {resetn} 0 0 ns, 1 {25ns}
force {cards[5:0]} 2#010010
force {cards[11:6]} 2#010010
force {cards[17:12]} 2#010010
force {cards[23:18]} 2#010010
force {cards[29:24]} 2#010010
force {cards[35:30]} 2#010010
force {cards[41:36]} 2#010010
force {cards[47:42]} 2#010010
force {cards[53:48]} 2#010010
force {faceup[8:0]} 2#000000011
force {cursorID[1:0]} 2#00

# draw once
force {go} 0 0ns, 1 {50ns}
force {go} 0 70ns
#run simulation for a few ns
run 7ms
