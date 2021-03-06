require 'mimey/cpu/operations'

module Mimey
  class Emulator
    attr_accessor :debug_mode, :step_by_step

    def initialize(cpu_options = {})
      cpu_options = CPU::DEFAULTS.merge(cpu_options)
      @cpu = CPU.new(cpu_options)
      @gpu = GPU.new(LcdScreen.new)
      @cpu.mmu.gpu = @gpu
      @gpu.cpu = @cpu
    end

    def load_rom(path)
      rom = File.binread(path)
      @cpu.load_with(*rom.unpack("C*"))
    end

    def run
      reset
      loop do
        step
        gets if step_by_step
      end
    end

    def reset
      @cpu.reset
    end

    def step
      @cpu.step
      @cpu.debug if !!debug_mode
      @gpu.step
    end
  end
end
