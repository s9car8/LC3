
#include <stdint.h>
#include <cstring>
#include <unordered_map>
#include <array>
#include <vector>
#include <iostream>
#include <fstream>


typedef int16_t  i16;
typedef uint16_t u16;
typedef uint8_t  u8;

namespace cpu
{
    u16 Mem[0x10000];

    u16 PC = 0x200;
    u16 IR;
    u16 TEMP;
    bool interrupted;

    #define ENUM_FLAGS(o) \
        o(N) o(Z) o(P)

    #define o(n) n,
    enum Foffset { ENUM_FLAGS(o) };
    #undef o

    struct RegFile
    {
        u16 F;
        u16 R[8];
        unsigned sr1, sr2, dr;
    } r;

    namespace alu
    {
        u16 A, B;

        void Add() { A += B; }
        void And() { A &= B; }
        void Not() { A = ~A; }
    }

    namespace impl
    {
        void setcc()
        {
            r.F = (r.F & ~(1<<N)) | (((i16)r.R[r.dr] < 0) << N);
            r.F = (r.F & ~(1<<Z)) | (((i16)r.R[r.dr] == 0) << Z);
            r.F = (r.F & ~(1<<P)) | (((i16)r.R[r.dr] > 0) << P);
        }

        // NOTE(sergey): RET = JMP[BaseR == 7]

        #define SEXT(n, sp) ({ struct {u16 x: sp;} s; s.x = n; })
        #define SEXT5(n)  SEXT(n, 5)
        #define SEXT6(n)  SEXT(n, 6)
        #define SEXT9(n)  SEXT(n, 9)
        #define SEXT11(n) SEXT(n, 11)
        #define ZEXT(n) (n*8)

        #define LIST_INSTRUCTIONS(o) \
            o(0x1, r.dr = (IR>>9)&0x7; r.sr1 = (IR>>6)&0x7,, alu::A = r.R[r.sr1]; alu::B = (IR&0x20) ? SEXT5(IR&0x1F) : r.R[r.sr2], alu::Add(), r.R[r.dr] = alu::A) /* ADD */ \
            o(0x5, r.dr = (IR>>9)&0x7; r.sr1 = (IR>>6)&0x7,, alu::A = r.R[r.sr1]; alu::B = (IR&0x20) ? SEXT5(IR&0x1F) : r.R[r.sr2], alu::And(), r.R[r.dr] = alu::A) /* AND */ \
            o(0x0,, TEMP = PC + SEXT9(IR&0x01FF),, if ((IR>>9)&0x7 & (r.F & (1<<N | 1<<Z | 1<<P))) PC = TEMP,) /* BR */ \
            o(0xC,, TEMP = r.R[(IR>>6)&0x7],, PC = TEMP,) /* JMP|RET */ \
            o(0x4,, TEMP = (IR&0x800) ? PC + SEXT11(IR&0x7FF) : r.R[(IR>>6)&0x7],, PC = TEMP,) /* JSR|JSRR */ \
            o(0x2, r.dr = (IR>>9)&0x7, TEMP = PC + SEXT9(IR&0x1FF), r.R[r.dr] = Mem[TEMP], setcc(),) /* LD */ \
            o(0xA, r.dr = (IR>>9)&0x7, TEMP = PC + SEXT9(IR&0x1FF), r.R[r.dr] = Mem[Mem[TEMP]], setcc(),) /* LDI */ \
            o(0x6, r.dr = (IR>>9)&0x7, TEMP = r.R[(IR>>6)&0x7] + SEXT6(IR&0x3F), r.R[r.dr] = Mem[TEMP], setcc(),) /* LDR */ \
            o(0xE, r.dr = (IR>>9)&0x7, TEMP = PC + SEXT9(IR&0x1FF),, r.R[r.dr] = TEMP; setcc(),) /* LEA */ \
            o(0x9, r.dr = (IR>>9)&0x7; r.sr1 = (IR>>6)&0x7,, alu::A = r.R[r.sr1], alu::Not(); setcc(),) /* NOT */ \
            o(0x8,,,, PC = Mem[r.R[6]++]; TEMP = Mem[r.R[6]++]; /* PSR = TEMP */,) /* RTI */ /* TODO(sergey): Implement PSR check. */ \
            o(0x3, r.sr1 = (IR>>9)&0x7, TEMP = PC + SEXT9(IR&0x1FF),, Mem[TEMP] = r.R[r.sr1],) /* ST */ \
            o(0xB, r.sr1 = (IR>>9)&0x7, TEMP = PC + SEXT9(IR&0x1FF),, Mem[Mem[TEMP]] = r.R[r.sr1],) /* STI */ \
            o(0x7, r.sr1 = (IR>>9)&0x7, TEMP = r.R[(IR>>6)&0x7] + SEXT6(IR&0x3F),, Mem[TEMP] = r.R[r.sr1],) /* STR */ \
            o(0xF,,,, r.R[7] = PC; TEMP = IR&0xFF; if (TEMP == 0x25) { interrupted = true; std::cout << "LC3 was interrupted." << std::endl;  } else PC = Mem[ZEXT(TEMP)],) /* TRAP */

        #define m(opcode, d, a, o, e, s) \
            void Decode_##opcode() { d; } \
            void EvaluateAddress_##opcode() { a; } \
            void FetchOperands_##opcode() { o; } \
            void Execute_##opcode() { e; } \
            void StoreResult_##opcode() { s; }
        LIST_INSTRUCTIONS(m)
        #undef m
    }

    namespace impl
    {
        // Instruction cycle phase data structures goes below.
        unsigned opcode = 0x1;
        enum Phase
        {
            F, FETCH = F,
            D, DECODE = D,
            A, EVALUATE_ADDRESS = A,
            O, FETCH_OPERANDS = O,
            E, EXECUTE = E,
            S, STORE_RESULT = S
        } phase;

        // Phase phase_table[6] = {D, A, O, E, S, F};
        #define m(opcode, ...) \
            { opcode, {D, A, O, E, S, F} },
        std::unordered_map<unsigned, std::array<Phase, 6>> phase_table { LIST_INSTRUCTIONS(m) };
        #undef m

        void Fetch()
        {
            IR = Mem[PC];
            opcode = (IR>>12)&0xF;
            ++PC;
        }

        void DispatchPhase()
        {
            // static void (*phase_handler[][6])() = {
                // [FETCH]            = Fetch,
                // [DECODE]           = Decode,
                // [EVALUATE_ADDRESS] = EvaluateAddress,
                // [FETCH_OPERANDS]   = FetchOperands,
                // [EXECUTE]          = Execute,
                // [STORE_RESULT]     = StoreResult,
            // };
            #define m(opcode, ...) \
                { opcode, { \
                    Fetch, \
                    Decode_##opcode, \
                    EvaluateAddress_##opcode, \
                    FetchOperands_##opcode, \
                    Execute_##opcode, \
                    StoreResult_##opcode \
                }},
            static std::unordered_map<unsigned, std::array<void(*)(), 6>> phase_handler { LIST_INSTRUCTIONS(m) };
            #undef m

            phase_handler[opcode][phase]();
            phase = phase_table[opcode][phase];
        }
    }

    void Load(const u16* code, unsigned size, unsigned pos = 0x200)
    {
        std::memmove(Mem + pos, code, sizeof(u16[size]));
    }

    void Run()
    {
        while (!interrupted)
        {
            std::cout << "PC: 0x" << std::hex << PC << "; Op: 0x" << (IR) << "; Phase: " << impl::phase << std::dec << std::endl;
            impl::DispatchPhase();
        }
    }
}

int main(int argc, const char* args[])
{
    if (argc != 2) { std::cout << "Usage: lc3 <input-file>." << std::endl; return -1; }
    std::ifstream fin(argv[1], std::ios::binary);

    if (!fin.is_open()) { std::cout << "Couln't open file \'" << argv[1] << "\'." << std::endl; return -2; }

    fin.unsetf(std::ios::skipws);
    fin.seekg(0, std::ios::end);
    auto file_sz = static_cast<std::streampos>(fin.tellg());
    fin.seekg(0, std::ios::beg);

    std::vector<u16> code;

    code.resize(file_sz / sizeof(u16));
    fin.read((char*)code.data(), file_sz);

    cpu::Load(code.data(), code.size(), 0);
    cpu::Run();
    std::cout << cpu::alu::A << std::endl;
    return 0;
}
