`timescale 1ps / 1ps

//===========================================================
// File Path: D:/Projects/Vivado_Projects/UART_Controller/files/simulations/UART_CONTROLLER_TB.v
// Author: Kudryashov D.S.
// Created On: 2026-06-15 15:40:13
// Description: Top module test
//===========================================================

`ifndef TB_BAUDRATE_D
    `define TB_BAUDRATE_D 115200
`endif

`ifndef TB_RATIO_D
    `define TB_RATIO_D 16
`endif

`ifndef TB_PARITY_BIT_D
    `define TB_PARITY_BIT_D 0
`endif

`ifndef TB_STOP_BIT_D
    `define TB_STOP_BIT_D 0
`endif

module UART_CONTROLLER_TB;

    //===========================================================
    // Testbench configuration
    //===========================================================

    localparam integer TB_FREQ       = 100_000_000;
    localparam integer TB_BAUDRATE   = `TB_BAUDRATE_D;
    localparam integer TB_RATIO      = `TB_RATIO_D;
    localparam integer TB_PARITY_BIT = `TB_PARITY_BIT_D; // 0 - off, 1 - odd, 2 - even
    localparam integer TB_STOP_BIT   = `TB_STOP_BIT_D; // 0 - 1 stop bit, 1 - 2 stop bits

    localparam integer CLK_PERIOD_PS = 10_000; // 100 MHz ( (1 / TB_FREQ) * 10^12 ) 

    localparam integer SAMPLE_DIV = TB_FREQ / (TB_BAUDRATE * TB_RATIO);
    localparam integer BIT_CLKS   = SAMPLE_DIV * TB_RATIO;

    //===========================================================
    // Signals
    //===========================================================

    reg clk;
    reg rst_n;

    reg  rx;
    wire tx;

    wire       m_tvalid;
    wire [7:0] m_tdata;
    reg        m_tready;

    reg        s_tvalid;
    reg  [7:0] s_tdata;
    wire       s_tready;

    integer errors;
    integer tests;
    
    //===========================================================
    // DUT
    //===========================================================

    UART_CONTROLLER 
    #(
        .FREQ(TB_FREQ),
        .BAUDRATE(TB_BAUDRATE),
        .RATIO(TB_RATIO),
        .PARITY_BIT(TB_PARITY_BIT),
        .STOP_BIT(TB_STOP_BIT)
    )
    dut
    (
        .clk(clk),
        .rst_n(rst_n),

        .rx(rx),
        .tx(tx),

        .m_tvalid(m_tvalid),
        .m_tdata(m_tdata),
        .m_tready(m_tready),

        .s_tvalid(s_tvalid),
        .s_tdata(s_tdata),
        .s_tready(s_tready)
    );

    //===========================================================
    // Clock
    //===========================================================

    initial begin
        clk = 1'b0;
    end
    
    always #(CLK_PERIOD_PS / 2) clk = ~clk;
    
    //===========================================================
    // Parameter checks for simulation
    //===========================================================

    initial begin
        if (!valid_baudrate(TB_BAUDRATE)) begin
            $display("ERROR: Unsupported BAUDRATE = %0d", TB_BAUDRATE);
            $finish;
        end

        if ((TB_RATIO != 8) && (TB_RATIO != 16) && (TB_RATIO != 32)) begin
            $display("ERROR: Unsupported RATIO = %0d", TB_RATIO);
            $finish;
        end

        if (TB_FREQ < TB_BAUDRATE * TB_RATIO) begin
            $display("ERROR: TB_FREQ must be >= TB_BAUDRATE * TB_RATIO");
            $finish;
        end

        if ((TB_PARITY_BIT != 0) &&
            (TB_PARITY_BIT != 1) &&
            (TB_PARITY_BIT != 2)) begin
            $display("ERROR: Unsupported PARITY_BIT = %0d", TB_PARITY_BIT);
            $finish;
        end

        if ((TB_STOP_BIT != 0) && (TB_STOP_BIT != 1)) begin
            $display("ERROR: Unsupported STOP_BIT = %0d", TB_STOP_BIT);
            $finish;
        end
    end
    
    function valid_baudrate(input integer baudrate);
        begin
            case (baudrate)
                300,
                600,
                1200,
                1800,
                2400,
                3600,
                4800,
                7200,
                9600,
                14400,
                19200,
                28800,
                38400,
                57600,
                115200,
                230400,
                460800,
                921600: valid_baudrate = 1'b1;

                default: valid_baudrate = 1'b0;
            endcase
        end
    endfunction
    
    //===========================================================
    // Basic utility tasks
    //===========================================================

    task tick();
        begin
            @(posedge clk);
        end
    endtask

    task wait_clks(input integer n);
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                tick();
            end
        end
    endtask
    
    task tb_error(input [1023:0] msg);
        begin
            errors = errors + 1;
            $display("[%0t] ERROR: %0s", $time, msg);
        end
    endtask

    task tb_pass(input [1023:0] msg);
        begin
            $display("[%0t] PASS: %0s", $time, msg);
        end
    endtask
    
    task apply_reset;
        begin
            rx = 1'b1;

            m_tready = 1'b1;

            s_tvalid = 1'b0;
            s_tdata  = 8'h00;

            rst_n = 1'b0;
            wait_clks(20);

            rst_n = 1'b1;
            wait_clks(20);
        end
    endtask
    
    //===========================================================
    // Parity helpers
    //===========================================================

    function calc_parity_bit(input [7:0] data);
        begin
            if (TB_PARITY_BIT == 1) begin
                calc_parity_bit = ~(^data); // odd
            end else if (TB_PARITY_BIT == 2) begin
                calc_parity_bit = (^data);  // even
            end else begin
                calc_parity_bit = 1'b1;     // unused
            end
        end
    endfunction

    function integer frame_bits_count(input dummy);
        begin
            frame_bits_count = 1 + 8; // start + data
    
            if (TB_PARITY_BIT != 0)
                frame_bits_count = frame_bits_count + 1;
    
            if (TB_STOP_BIT == 0)
                frame_bits_count = frame_bits_count + 1;
            else
                frame_bits_count = frame_bits_count + 2;
        end
    endfunction
    
    //===========================================================
    // RX stimulus tasks
    //===========================================================

    task drive_rx_bit(input bit_value);
        begin
            rx = bit_value;
            wait_clks(BIT_CLKS);
        end
    endtask
    
    task uart_rx_send_frame(input [7:0] data, input break_parity, input break_stop);
        integer i;
        reg parity_bit;
        begin
            // Idle before frame
            drive_rx_bit(1'b1);

            // Start bit
            drive_rx_bit(1'b0);

            // Data bits, LSB first
            for (i = 0; i < 8; i = i + 1) begin
                drive_rx_bit(data[i]);
            end

            // Optional parity bit
            if (TB_PARITY_BIT != 0) begin
                parity_bit = calc_parity_bit(data);

                if (break_parity)
                    parity_bit = ~parity_bit;

                drive_rx_bit(parity_bit);
            end

            // Stop bit / bits
            if (TB_STOP_BIT == 0) begin
                if (break_stop)
                    drive_rx_bit(1'b0);
                else
                    drive_rx_bit(1'b1);
            end else begin
                if (break_stop) begin
                    drive_rx_bit(1'b1);
                    drive_rx_bit(1'b0);
                end else begin
                    drive_rx_bit(1'b1);
                    drive_rx_bit(1'b1);
                end
            end

            // Back to idle
            drive_rx_bit(1'b1);
        end
    endtask

    task uart_rx_send_byte(input [7:0] data);
        begin
            uart_rx_send_frame(data, 1'b0, 1'b0);
        end
    endtask
    
    task automatic uart_idle_gap(input integer bit_count);
        begin
            rx = 1'b1;
            wait_clks(BIT_CLKS * bit_count);
        end
    endtask
    
    //===========================================================
    // RX checker tasks
    //===========================================================

    task expect_rx_byte(input [7:0] expected_data, input integer timeout_clks);
        integer cnt;
        reg found;
        begin
            tests = tests + 1;
            found = 1'b0;
            cnt = 0;

            while ((cnt < timeout_clks) && (!found)) begin
                tick();

                if (m_tvalid) begin
                    found = 1'b1;
                end

                cnt = cnt + 1;
            end

            if (!found) begin
                tb_error("RX timeout: m_tvalid was not asserted");
            end else begin
                if (m_tdata !== expected_data) begin
                    $display("[%0t] ERROR: RX data mismatch. expected = 0x%02h, got = 0x%02h",
                             $time, expected_data, m_tdata);
                    errors = errors + 1;
                end else begin
                    $display("[%0t] PASS: RX received 0x%02h", $time, m_tdata);
                end
            end
        end
    endtask

    task expect_no_rx_byte(input integer observe_clks);
        integer i;
        reg got_valid;
        begin
            tests = tests + 1;
            got_valid = 1'b0;

            for (i = 0; i < observe_clks; i = i + 1) begin
                tick();

                if (m_tvalid)
                    got_valid = 1'b1;
            end

            if (got_valid) begin
                tb_error("RX produced m_tvalid for invalid frame");
            end else begin
                tb_pass("RX ignored invalid frame");
            end
        end
    endtask
    
    //===========================================================
    // TX AXI driver tasks
    //===========================================================

    task axi_send_byte_to_tx(input [7:0] data);
        integer timeout;
        begin
            tests = tests + 1;
            timeout = 0;

            while ((!s_tready) && (timeout < 10000)) begin
                tick();
                timeout = timeout + 1;
            end

            if (!s_tready) begin
                tb_error("TX timeout: s_tready was not asserted");
            end else begin
                s_tdata  = data;
                s_tvalid = 1'b1;

                tick();

                s_tvalid = 1'b0;
                s_tdata  = 8'h00;
            end
        end
    endtask
    
    //===========================================================
    // TX checker tasks
    //===========================================================

    task expect_tx_frame(input [7:0] expected_data);
        integer timeout;
        integer i;
        reg [7:0] received_data;
        reg expected_parity;
        begin
            tests = tests + 1;
            received_data = 8'h00;
            timeout = 0;

            // Wait start bit
            while ((tx == 1'b1) && (timeout < BIT_CLKS * 4)) begin
                tick();
                timeout = timeout + 1;
            end

            if (tx !== 1'b0) begin
                tb_error("TX start bit timeout");
            end else begin
                // Check middle of start bit
                wait_clks(BIT_CLKS / 2);

                if (tx !== 1'b0) begin
                    tb_error("TX invalid start bit");
                end

                // Data bits, LSB first
                for (i = 0; i < 8; i = i + 1) begin
                    wait_clks(BIT_CLKS);
                    received_data[i] = tx;
                end

                if (received_data !== expected_data) begin
                    $display("[%0t] ERROR: TX data mismatch. expected = 0x%02h, got = 0x%02h",
                             $time, expected_data, received_data);
                    errors = errors + 1;
                end else begin
                    $display("[%0t] PASS: TX data 0x%02h", $time, received_data);
                end

                // Optional parity
                if (TB_PARITY_BIT != 0) begin
                    wait_clks(BIT_CLKS);
                    expected_parity = calc_parity_bit(expected_data);

                    if (tx !== expected_parity) begin
                        $display("[%0t] ERROR: TX parity mismatch. expected = %b, got = %b",
                                 $time, expected_parity, tx);
                        errors = errors + 1;
                    end else begin
                        tb_pass("TX parity bit checked");
                    end
                end

                // Stop bit 1
                wait_clks(BIT_CLKS);

                if (tx !== 1'b1) begin
                    tb_error("TX invalid stop bit 1");
                end

                // Stop bit 2
                if (TB_STOP_BIT == 1) begin
                    wait_clks(BIT_CLKS);

                    if (tx !== 1'b1) begin
                        tb_error("TX invalid stop bit 2");
                    end
                end

                tb_pass("TX frame checked");
            end
        end
    endtask
    
    //===========================================================
    // Test scenarios
    //===========================================================

    task test_reset_idle;
        begin
            tests = tests + 1;

            if (tx !== 1'b1) begin
                tb_error("TX must be idle high after reset");
            end else begin
                tb_pass("TX is idle high after reset");
            end

            if (s_tready !== 1'b1) begin
                tb_error("s_tready must be 1 after reset");
            end else begin
                tb_pass("s_tready is 1 after reset");
            end

            if (m_tvalid !== 1'b0) begin
                tb_error("m_tvalid must be 0 after reset");
            end else begin
                tb_pass("m_tvalid is 0 after reset");
            end
        end
    endtask

    task test_rx_one_byte(input [7:0] data);
        begin
            fork
                begin
                    uart_rx_send_byte(data);
                end

                begin
                    expect_rx_byte(data, BIT_CLKS * (frame_bits_count(1'b0) + 4));
                end
            join
        end
    endtask
    
    task test_rx_bad_parity;
        begin
            if (TB_PARITY_BIT != 0) begin
                fork
                    begin
                        uart_rx_send_frame(8'h5A, 1'b1, 1'b0);
                    end

                    begin
                        expect_no_rx_byte(BIT_CLKS * (frame_bits_count(1'b0) + 4));
                    end
                join
                uart_idle_gap(10);
            end else begin
                tb_pass("Bad parity test skipped: parity is disabled");
            end
        end
    endtask

    task test_rx_bad_stop;
        begin
            fork
                begin
                    uart_rx_send_frame(8'hA5, 1'b0, 1'b1);
                end

                begin
                    expect_no_rx_byte(BIT_CLKS * (frame_bits_count(1'b0) + 4));
                end
            join
            uart_idle_gap(10);
        end
    endtask
    
    task test_rx_backpressure(input [7:0] data);
        begin
            m_tready = 1'b0;

            fork
                begin
                    uart_rx_send_byte(data);
                end

                begin
                    expect_rx_byte(data, BIT_CLKS * (frame_bits_count(1'b1) + 4));
                end
            join

            wait_clks(20);

            if (m_tvalid !== 1'b1) begin
                tb_error("RX m_tvalid was not held while m_tready = 0");
            end

            if (m_tdata !== data) begin
                tb_error("RX m_tdata was not held while m_tready = 0");
            end

            m_tready = 1'b1;
            wait_clks(3);

            if (m_tvalid !== 1'b0) begin
                tb_error("RX m_tvalid was not cleared after m_tready");
            end else begin
                tb_pass("RX backpressure checked");
            end
        end
    endtask

    task test_tx_one_byte(input [7:0] data);
        begin
            fork
                begin
                    axi_send_byte_to_tx(data);
                end

                begin
                    expect_tx_frame(data);
                end
            join
        end
    endtask
    
    task test_tx_ready_busy;
        begin
            axi_send_byte_to_tx(8'h3C);

            wait_clks(5);

            if (s_tready !== 1'b0) begin
                tb_error("s_tready must be 0 while TX is busy");
            end else begin
                tb_pass("s_tready is 0 while TX is busy");
            end

            wait_clks(BIT_CLKS * (frame_bits_count(1'b0) + 2));

            if (s_tready !== 1'b1) begin
                tb_error("s_tready did not return to 1 after TX frame");
            end else begin
                tb_pass("s_tready returned to 1 after TX frame");
            end
        end
    endtask

    task test_all_rx_patterns;
        begin
            test_rx_one_byte(8'h00);
            test_rx_one_byte(8'hFF);
            test_rx_one_byte(8'h55);
            test_rx_one_byte(8'hAA);
            test_rx_one_byte(8'h01);
            test_rx_one_byte(8'h80);
            test_rx_one_byte(8'h7E);
            test_rx_one_byte(8'h81);
            test_rx_one_byte(8'hA5);
            test_rx_one_byte(8'h5A);
        end
    endtask

    task test_all_tx_patterns;
        begin
            test_tx_one_byte(8'h00);
            wait_clks(BIT_CLKS * 2);

            test_tx_one_byte(8'hFF);
            wait_clks(BIT_CLKS * 2);

            test_tx_one_byte(8'h55);
            wait_clks(BIT_CLKS * 2);

            test_tx_one_byte(8'hAA);
            wait_clks(BIT_CLKS * 2);

            test_tx_one_byte(8'h01);
            wait_clks(BIT_CLKS * 2);

            test_tx_one_byte(8'h80);
            wait_clks(BIT_CLKS * 2);

            test_tx_one_byte(8'h7E);
            wait_clks(BIT_CLKS * 2);

            test_tx_one_byte(8'h81);
            wait_clks(BIT_CLKS * 2);
        end
    endtask

    //===========================================================
    // Main
    //===========================================================
    
    initial begin
        errors = 0;
        tests  = 0;
        
        $display("====================================================");
        $display("UART_CONTROLLER_TB started");
        $display("TB_FREQ       = %0d", TB_FREQ);
        $display("TB_BAUDRATE   = %0d", TB_BAUDRATE);
        $display("TB_RATIO      = %0d", TB_RATIO);
        $display("TB_PARITY_BIT = %0d", TB_PARITY_BIT);
        $display("TB_STOP_BIT   = %0d", TB_STOP_BIT);
        $display("SAMPLE_DIV    = %0d", SAMPLE_DIV);
        $display("BIT_CLKS      = %0d", BIT_CLKS);
        $display("FRAME_BITS    = %0d", frame_bits_count(1'b0));
        $display("====================================================");

        apply_reset();

        test_reset_idle();

        test_all_rx_patterns();
        test_rx_bad_parity();
        test_rx_bad_stop();
        test_rx_backpressure(8'hD7);

        test_all_tx_patterns();
        test_tx_ready_busy();

        wait_clks(100);

        $display("====================================================");
        $display("Tests finished");
        $display("Total checks = %0d", tests);
        $display("Errors       = %0d", errors);
        $display("====================================================");

        if (errors == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL");
        end

        $finish;
    end
    
endmodule
