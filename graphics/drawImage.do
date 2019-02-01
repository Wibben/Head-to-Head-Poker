# set the working dir, where all compiled verilog goes
vlib work

# compile all verilog modules in mux.v to working dir
# could also have multiple verilog files
vlog drawImage.v
vlog ../resources/ROMS/playingCards.v
vlog ../resources/ROMS/cardBack.v
vlog ../resources/ROMS/background.v
vlog ../resources/ROMS/menu.v
vlog ../resources/ROMS/cursor.v
vlog ../resources/ROMS/winnerName.v

#load top level simulation module
vsim -L altera_mf_ver drawImage

# log all signals and add some signals to waveform window
log {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}

#clock
force {clock} 0 0ns, 1 {10ns} -r 20ns

# reset
force {resetn} 0 0 ns, 1 {25ns}
force {card[5:0]} 2#010010
force {menuOFF} 2#0000 
force {menuDepth} 2#00
force {winID} 2#01

# menu
force {drawID[3:0]} 2#0011
force {menuID} 2#00
force {go} 0 0ns, 1 {50ns}
force {go} 0 70ns
#run simulation for a few ns
run 0.5ms

