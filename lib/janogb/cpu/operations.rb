module JanoGB
  class CPU
    # NOP, opcode 0x00. Does nothing
    def nop
      @clock += 1
    end
    
    # LD RR,nn operations. Loads a 16 bits value to a 16 bits register
    [:bc, :de, :hl, :sp].each do |r|
      method_name = "ld_#{r}_nn"
      define_method(method_name) do
        send "#{r}=", next_word
        @clock += 3
      end
    end
    
    # LD (RR), A operations. Loads the A register into the
    # 16 bit memory direction pointed by RR regiser
    [:bc, :de, :hl].each do |r|
      method_name = "ld_m#{r}_a"
      define_method(method_name) do
        address = send "#{r}"
        @mmu[address] = @a
        @clock += 2
      end
    end

    # INC RR operations. Increment RR register by 1. If current register value is 0xFFFF,
    # it will be 0x0000 after method execution
    [:bc, :de, :hl, :sp].each do |r|
      method_name = "inc_#{r}"
      define_method(method_name) do
        value = send "#{r}"
        send "#{r}=", (value + 1) & 0xFFFF
        @clock += 2
      end
    end
    
    # INC B operations. Increment R register by 1
    # Sets Z flag if result is 0
    # Resets N flag
    # Sets H flag if carry from bit 3
    # C flag is not affected
    [:b, :c, :d, :e, :h, :l, :a].each do |r|
      method_name = "inc_#{r}"
      define_method(method_name) do
        value = instance_variable_get "@#{r}"
        new_value = (value + 1) & 0xFF
        instance_variable_set "@#{r}", new_value
        @f &= C_FLAG
        @f |= Z_FLAG  if new_value == 0x00
        @f |= H_FLAG  if (new_value & 0x0F) == 0x00
        @clock += 1
      end
    end
    
    # DEC B operations. Decrement R register by 1
    # Sets Z flag if result is 0
    # Sets N flag
    # Sets H flag if no borrow from bit 4
    # C flag is not affected
    [:b, :c, :d, :e, :h, :l, :a].each do |r|
      method_name = "dec_#{r}"
      define_method(method_name) do
        value = instance_variable_get "@#{r}"
        new_value = (value - 1) & 0xFF
        instance_variable_set "@#{r}", new_value
        @f &= C_FLAG
        @f |= N_FLAG
        @f |= Z_FLAG  if new_value == 0x00
        @f |= H_FLAG  if (new_value & 0x0F) == 0x0F
        @clock += 1
      end
    end
    
    # LD R,n operations. Loads a 8 bits value to a 8 bits register
    [:b, :c, :d, :e, :h, :l, :a].each do |r|
      method_name = "ld_#{r}_n"
      define_method(method_name) do
        instance_variable_set "@#{r}", next_byte
        @clock += 2
      end
    end
    
    # LD (NN),SP. Loads the 16 bits SP register into 16 bits memory direction NN
    def ld_mnn_sp
      @mmu.word[next_word] = sp
      @clock += 5
    end
    
    # ADD HL,RR operations. Adds a 16 bits register to HL
    [:bc, :de, :hl, :sp].each do |r|
      method_name = "add_hl_#{r}"
      define_method(method_name) do
        to_add = send "#{r}"
        sum = hl + to_add
        @f &= Z_FLAG
        @f |= H_FLAG  if (hl & 0x0FFF) + (to_add & 0x0FFF) > 0x0FFF
        @f |= C_FLAG  if sum > 0xFFFF
        self.hl = sum & 0xFFFF
        @clock += 2
      end
    end
    
    # LD A,(RR) operations. Loads the memory pointed by RR register
    # into the A register
    [:bc, :de, :hl].each do |r|
      method_name = "ld_a_m#{r}"
      define_method(method_name) do
        address = send "#{r}"
        @a = @mmu[address]
        @clock += 2
      end
    end
    
    # DEC RR operations. Decrement RR register by 1. If current register value is 0x0000,
    # it will be 0xFFFF after method execution
    [:bc, :de, :hl, :sp].each do |r|
      method_name = "dec_#{r}"
      define_method(method_name) do
        value = send "#{r}"
        send "#{r}=", (value - 1) & 0xFFFF
        @clock += 2
      end
    end
    
    # RLCA. Rotates to the left the A register, loads the bit 7 into the C flag
    # Resets Z, N and H flags
    def rlca
      @f &= C_FLAG
      @f |= C_FLAG  if (@a & 0x80) == 0x80
      @a = ((@a << 1) | (@a >> 7)) & 0xFF
      @clock += 1
    end
    
    # RRCA. Rotates to the left the A register, loads the bit 0 into the C flag
    # Resets Z, N and H flags
    def rrca
      @f &= C_FLAG
      @f |= C_FLAG  if (@a & 0x01) == 0x01
      @a = ((@a >> 1) | ((@a & 0x01) << 7)) & 0xFF
      @clock += 1
    end
    
    # LD R,R operations. Load a 8 bit register into another
    [:b, :c, :d, :e, :h, :l, :a].each do |r1|
      [:b, :c, :d, :e, :h, :l, :a].each do |r2|
        method_name = "ld_#{r1}_#{r2}"
        define_method(method_name) do
          value = instance_variable_get "@#{r2}"
          instance_variable_set "@#{r1}", value
          @clock += 1
        end
      end
    end  
    
    # LD R,(HL) operations. Load the memory pointed by register HL into a 8 bits register
    [:b, :c, :d, :e, :h, :l].each do |r|
      method_name = "ld_#{r}_mhl"
      define_method(method_name) do
        instance_variable_set "@#{r}", @mmu[hl]
        @clock += 2
      end
    end
    
    # LD (HL),R operations. Load a 8 bits register into the memory pointed by register HL 
    [:b, :c, :d, :e, :h, :l].each do |r|
      method_name = "ld_mhl_#{r}"
      define_method(method_name) do
        value = instance_variable_get "@#{r}"
        @mmu[hl] = value
        @clock += 2
      end
    end
    
    # LDI (HL),A. Loads the A register into the memory pointed by HL, and then increments HL
    def ldi_mhl_a
      @mmu[hl] = @a
      self.hl = (hl + 1) & 0xFFFF
      @clock += 2
    end
    
    # LDI A,(HL). Loads the memory pointed by HL into the A register, and then increments HL
    def ldi_a_mhl
      @a = @mmu[hl]
      self.hl = (hl + 1) & 0xFFFF
      @clock += 2
    end
    
    # LDD (HL),A. Loads the A register into the memory pointed by HL, and then decrements HL
    def ldd_mhl_a
      @mmu[hl] = @a
      self.hl = (hl - 1) & 0xFFFF
      @clock += 2
    end
    
    # LDD A,(HL). Loads the memory pointed by HL into the A register, and then decrements HL
    def ldd_a_mhl
      @a = @mmu[hl]
      self.hl = (hl - 1) & 0xFFFF
      @clock += 2
    end
    
    # LD (HL),n. Loads a 8 bit number into the memory pointed by HL
    def ld_mhl_n
      @mmu[hl] = next_byte
      @clock += 3
    end

    # Operations array, indexes methods names by opcode
    OPERATIONS = [
      # 0x00
      :nop, :ld_bc_nn, :ld_mbc_a, :inc_bc, :inc_b, :dec_b, :ld_b_n, :rlca, :ld_mnn_sp, :add_hl_bc, :ld_a_mbc, :dec_bc, :inc_c, :dec_c, :ld_c_n, :rrca,
      # 0x10
      :_10, :ld_de_nn, :ld_mde_a, :inc_de, :inc_d, :dec_d, :ld_d_n, :_17, :_18, :add_hl_de, :ld_a_mde, :dec_de, :inc_e, :dec_e, :ld_e_n, :_1F,
      # 0x20
      :_20, :ld_hl_nn, :ldi_mhl_a, :inc_hl, :inc_h, :dec_h, :ld_h_n, :_27, :_28, :add_hl_hl, :ldi_a_mhl, :dec_hl, :inc_l, :dec_l, :ld_l_n, :_2F,
      # 0x30
      :_30, :ld_sp_nn, :ldd_mhl_a, :inc_sp, :_34, :_35, :ld_mhl_n, :_37, :_38, :add_hl_sp, :ldd_a_mhl, :dec_sp, :inc_a, :dec_a, :ld_a_n, :_3F,
      #0x40
      :ld_b_b, :ld_b_c, :ld_b_d, :ld_b_e, :ld_b_h, :ld_b_l, :ld_b_mhl, :ld_b_a, :ld_c_b, :ld_c_c, :ld_c_d, :ld_c_e, :ld_c_h, :ld_c_l, :ld_c_mhl, :ld_c_a,
      #0x50
       :ld_d_b, :ld_d_c, :ld_d_d, :ld_d_e, :ld_d_h, :ld_d_l, :ld_d_mhl, :ld_d_a, :ld_e_b, :ld_e_c, :ld_e_d, :ld_e_e, :ld_e_h, :ld_e_l, :ld_e_mhl, :ld_e_a,
      #0x60
      :ld_h_b, :ld_h_c, :ld_h_d, :ld_h_e, :ld_h_h, :ld_h_l, :ld_h_mhl, :ld_h_a, :ld_l_b, :ld_l_c, :ld_l_d, :ld_l_e, :ld_l_h, :ld_l_l, :ld_l_mhl, :ld_l_a,
      #0x70
      :ld_mhl_b, :ld_mhl_c, :ld_mhl_d, :ld_mhl_e, :ld_mhl_h, :ld_mhl_l, :_76, :ld_mhl_a, :ld_a_b, :ld_a_c, :ld_a_d, :ld_a_e, :ld_a_h, :ld_a_l, :ld_a_mhl, :ld_a_a
    ].freeze
  end
end