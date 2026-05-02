import cocotb
from cocotb.clock import Clock  # This was the missing part!
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_neural_net_digits(dut):
    dut._log.info("Starting Seven Segment Neural Network Test...")

    # Start the clock: 10us period = 100kHz
    # We use 'Clock' directly now
    cocotb.start_soon(Clock(dut.clk, 10, units="us").start())

    # Reset
    dut._log.info("Resetting...")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

    # Dictionary of inputs (Digit: Segment_Pattern)
    segments = {
        0: 0b00111111, # Digit 0
        1: 0b00000110, # Digit 1
        4: 0b01100110, # Digit 4
        9: 0b01101111  # Digit 9
    }

    for expected, pattern in segments.items():
        dut.ui_in.value = pattern
        
        # Give the clock 5 cycles to let the 'always' block register the prediction
        await ClockCycles(dut.clk, 5) 
        
        # Read uo_out (extract lower 4 bits)
        actual = int(dut.uo_out.value) & 0x0F
        
        if actual == expected:
            dut._log.info(f"PASS: Input {pattern:08b} correctly predicted {actual}")
        else:
            dut._log.error(f"FAIL: Input {pattern:08b} expected {expected}, got {actual}")
            assert actual == expected
