`timescale 1ns/1ps

// Top-level testbench module that simulates the entire transmission chain.
module transmission_sim;

  // Data arrays:
  // We use vectors for the 130-bit original/received data and the 156-bit encoded data.
  reg [129:0] original_data;
  reg [129:0] received_first;
  reg [155:0] encoded_data;
  reg [155:0] received_second;
  reg [129:0] decoded_data;
  
  integer i, j, block;
  integer error_count, first_error_count, second_error_count;
  integer rand_flip; // used for error injection

  // CRC values for the whole word and for each 6-bit block.
  reg [7:0] crc_original, crc_received;
  reg [7:0] crc_block_original, crc_block_received;
  
  /////////////////////////////////////////////////////////////////////////////
  // 5B/6B ENCODING FUNCTION
  /////////////////////////////////////////////////////////////////////////////
  // This function implements the lookup table from the Arduino code.
  function [5:0] encode5b6b;
    input [4:0] in;
    begin
      case(in)
        5'b00000: encode5b6b = 6'b100111;
        5'b00001: encode5b6b = 6'b011101;
        5'b00010: encode5b6b = 6'b101101;
        5'b00011: encode5b6b = 6'b110001;
        5'b00100: encode5b6b = 6'b110101;
        5'b00101: encode5b6b = 6'b101001;
        5'b00110: encode5b6b = 6'b011001;
        5'b00111: encode5b6b = 6'b111000;
        5'b01000: encode5b6b = 6'b111001;
        5'b01001: encode5b6b = 6'b100101;
        5'b01010: encode5b6b = 6'b010101;
        5'b01011: encode5b6b = 6'b110100;
        5'b01100: encode5b6b = 6'b001101;
        5'b01101: encode5b6b = 6'b101100;
        5'b01110: encode5b6b = 6'b011100;
        5'b01111: encode5b6b = 6'b010111;
        5'b10000: encode5b6b = 6'b011011;
        5'b10001: encode5b6b = 6'b100011;
        5'b10010: encode5b6b = 6'b010011;
        5'b10011: encode5b6b = 6'b110010;
        5'b10100: encode5b6b = 6'b001011;
        5'b10101: encode5b6b = 6'b101010;
        5'b10110: encode5b6b = 6'b011010;
        5'b10111: encode5b6b = 6'b111010;
        5'b11000: encode5b6b = 6'b110011;
        5'b11001: encode5b6b = 6'b100110;
        5'b11010: encode5b6b = 6'b010110;
        5'b11011: encode5b6b = 6'b110110;
        5'b11100: encode5b6b = 6'b001110;
        5'b11101: encode5b6b = 6'b101110;
        5'b11110: encode5b6b = 6'b011110;
        5'b11111: encode5b6b = 6'b101011;
        default:   encode5b6b = 6'b000000;
      endcase
    end
  endfunction
  
  /////////////////////////////////////////////////////////////////////////////
  // 6B/5B DECODING FUNCTION
  /////////////////////////////////////////////////////////////////////////////
  // This function finds the matching 5-bit value for a given 6-bit code.
  function [4:0] decode6b5b;
    input [5:0] in;
    begin
      case(in)
        6'b100111: decode6b5b = 5'b00000;
        6'b011101: decode6b5b = 5'b00001;
        6'b101101: decode6b5b = 5'b00010;
        6'b110001: decode6b5b = 5'b00011;
        6'b110101: decode6b5b = 5'b00100;
        6'b101001: decode6b5b = 5'b00101;
        6'b011001: decode6b5b = 5'b00110;
        6'b111000: decode6b5b = 5'b00111;
        6'b111001: decode6b5b = 5'b01000;
        6'b100101: decode6b5b = 5'b01001;
        6'b010101: decode6b5b = 5'b01010;
        6'b110100: decode6b5b = 5'b01011;
        6'b001101: decode6b5b = 5'b01100;
        6'b101100: decode6b5b = 5'b01101;
        6'b011100: decode6b5b = 5'b01110;
        6'b010111: decode6b5b = 5'b01111;
        6'b011011: decode6b5b = 5'b10000;
        6'b100011: decode6b5b = 5'b10001;
        6'b010011: decode6b5b = 5'b10010;
        6'b110010: decode6b5b = 5'b10011;
        6'b001011: decode6b5b = 5'b10100;
        6'b101010: decode6b5b = 5'b10101;
        6'b011010: decode6b5b = 5'b10110;
        6'b111010: decode6b5b = 5'b10111;
        6'b110011: decode6b5b = 5'b11000;
        6'b100110: decode6b5b = 5'b11001;
        6'b010110: decode6b5b = 5'b11010;
        6'b110110: decode6b5b = 5'b11011;
        6'b001110: decode6b5b = 5'b11100;
        6'b101110: decode6b5b = 5'b11101;
        6'b011110: decode6b5b = 5'b11110;
        6'b101011: decode6b5b = 5'b11111;
        default:   decode6b5b = 5'bx; // error indicator
      endcase
    end
  endfunction

  /////////////////////////////////////////////////////////////////////////////
  // CRC8 FUNCTIONS
  /////////////////////////////////////////////////////////////////////////////
  // Calculate CRC8 over 130 bits using polynomial 0x07.
  function [7:0] calc_crc8_130;
    input [129:0] data;
    integer i, j;
    reg [7:0] crc;
    begin
      crc = 8'b0;
      for(i = 0; i < 130; i = i + 1) begin
        // Incorporate each bit (using bit i as the least‐significant bit of the “byte”)
        crc = crc ^ (data[i] ? 8'h80 : 8'h00);
        for(j = 0; j < 8; j = j + 1) begin
          if(crc[7])
            crc = (crc << 1) ^ 8'h07;
          else
            crc = crc << 1;
        end
      end
      calc_crc8_130 = crc;
    end
  endfunction

  // Calculate CRC8 over a 6‑bit block.
  function [7:0] calc_crc8_6;
    input [5:0] data;
    integer j, k;
    reg [7:0] crc;
    begin
      crc = 8'b0;
      for(j = 0; j < 6; j = j + 1) begin
        crc = crc ^ (data[j] ? 8'h80 : 8'h00);
        for(k = 0; k < 8; k = k + 1) begin
          if(crc[7])
            crc = (crc << 1) ^ 8'h07;
          else
            crc = crc << 1;
        end
      end
      calc_crc8_6 = crc;
    end
  endfunction

  /////////////////////////////////////////////////////////////////////////////
  // MAIN INITIAL BLOCK (SIMULATION OF THE TRANSMISSION SYSTEM)
  /////////////////////////////////////////////////////////////////////////////
  initial begin
    // Initialize error counts.
    error_count = 0;
    first_error_count = 0;
    second_error_count = 0;
    
    // 1. Generate a 130-bit original data word.
    //    Set control bits: bit0 = 0 and bit1 = 1.
    original_data[0] = 0;
    original_data[1] = 1;
    for(i = 2; i < 130; i = i + 1) begin
      original_data[i] = $random % 2;
    end

    $display("Original Data (130 bits):");
    for(i = 0; i < 130; i = i + 1)
      $write("%0d", original_data[i]);
    $display("\n");

    // 2. First Transmission: TX1 -> RX2
    //    Transmit bit-by-bit; here we simulate an error by flipping bit 50.
    $display("=== First Transmission (130 bits) ===");
    for(i = 0; i < 130; i = i + 1) begin
      if(i == 50) begin
        $display("Flipping bit at position %0d", i);
        received_first[i] = ~original_data[i];  // error injection
      end else begin
        received_first[i] = original_data[i];
      end
      $display("Bit %0d: Sent %0d, Received %0d", i, original_data[i], received_first[i]);
    end

    // 3. Calculate and compare CRC for the 130-bit word.
    crc_original = calc_crc8_130(original_data);
    crc_received = calc_crc8_130(received_first);
    if(crc_original !== crc_received) begin
      first_error_count = first_error_count + 1;
      $display("FIRST TRANSMISSION CRC MISMATCH: Original CRC = %h, Received CRC = %h", 
                crc_original, crc_received);
    end else
      $display("FIRST TRANSMISSION CRC MATCH: %h", crc_original);

    // 4. Encoding: Convert the 130-bit received data into 156 bits
    //    by splitting into 26 blocks of 5 bits each and mapping each block.
    //    (Also note that the Arduino code replaces the first two bits with 0,0.)
    received_first[0] = 0;
    received_first[1] = 0;
    for(block = 0; block < 26; block = block + 1) begin
      // Extract 5 bits from the received_first vector.
      // (Using the part-select operator; synthesis tools supporting SystemVerilog use [start +: width])
      // For compatibility with Verilog-2001, you can also use: 
      //   five_bits = received_first[block*5+4 -: 5];
      reg [4:0] five_bits;
      five_bits = received_first[block*5 +: 5];
      
      // Map the 5-bit block to 6 bits.
      encoded_data[block*6 +: 6] = encode5b6b(five_bits);
      $display("Encoding Block %0d: 5-bit %b -> 6-bit %b", block, five_bits, encode5b6b(five_bits));
    end

    // 5. Second Transmission: TX2 -> RX1
    //    For each 6-bit block, transmit the bits and inject a single-bit error (randomly chosen).
    $display("\n=== Second Transmission (156 bits) ===");
    for(block = 0; block < 26; block = block + 1) begin
      // Choose one random bit in the current 6-bit block to flip.
      rand_flip = $random % 6;
      $display("Block %0d: Flipping bit position %0d in the 6-bit block", block, rand_flip);
      for(j = 0; j < 6; j = j + 1) begin
        if(j == rand_flip)
          received_second[block*6 + j] = ~encoded_data[block*6 + j];
        else
          received_second[block*6 + j] = encoded_data[block*6 + j];
        $display("  Block %0d, Bit %0d: Sent %0d, Received %0d", block, j, 
                 encoded_data[block*6 + j], received_second[block*6 + j]);
      end
      
      // Calculate the CRC for this 6-bit block.
      crc_block_original = calc_crc8_6(encoded_data[block*6 +: 6]);
      crc_block_received = calc_crc8_6(received_second[block*6 +: 6]);
      if(crc_block_original !== crc_block_received) begin
        second_error_count = second_error_count + 1;
        $display("  Block %0d CRC MISMATCH: Original CRC = %h, Received CRC = %h",
                 block, crc_block_original, crc_block_received);
      end else
        $display("  Block %0d CRC MATCH: %h", block, crc_block_original);
    end

    // 6. Decoding: Convert the 156-bit received data back into 130 bits.
    $display("\n=== Decoding Stage ===");
    for(block = 0; block < 26; block = block + 1) begin
      reg [5:0] six_bits;
      reg [4:0] five_bits_decoded;
      six_bits = received_second[block*6 +: 6];
      five_bits_decoded = decode6b5b(six_bits);
      decoded_data[block*5 +: 5] = five_bits_decoded;
      $display("Block %0d: 6-bit %b -> Decoded 5-bit %b", block, six_bits, five_bits_decoded);
    end

    // 7. Compare the original and decoded 130-bit data (ignoring the first two control bits).
    for(i = 2; i < 130; i = i + 1) begin
      if(original_data[i] !== decoded_data[i]) begin
        error_count = error_count + 1;
        $display("Mismatch at bit %0d: Original %0d, Decoded %0d", 
                 i, original_data[i], decoded_data[i]);
      end
    end

    $display("\n=== Transmission Complete ===");
    $display("Data bit errors: %0d", error_count);
    $display("First transmission CRC errors: %0d", first_error_count);
    $display("Second transmission CRC errors: %0d", second_error_count);
    
    $finish;
  end

endmodule
