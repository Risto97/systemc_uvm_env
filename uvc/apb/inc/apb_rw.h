#ifndef APB_RW_H_
#define APB_RW_H_

#include <systemc>
#include <uvm>
#include <crave2uvm.h>

namespace uvc::apb{
    typedef enum {
        READ = 0,
        WRITE = 1
    } rw_enum;

    class rw : public uvm_randomized_sequence_item {
        public:
            sc_dt::sc_bv<32> addr; 
            crave::crv_variable < sc_dt::sc_bv<32> > rnd;
            sc_dt::sc_bv<32> data;
            sc_dt::sc_bv<4>  strb;
            rw_enum kind_e;
            bool slv_err;
            bool valid;

            UVM_OBJECT_UTILS(rw);

            rw(const std::string & name = "apb_rw") :
                uvm_randomized_sequence_item(name) {}

            virtual void do_print(const uvm::uvm_printer& printer) const;
            virtual void do_pack(uvm::uvm_packer& p) const;
            virtual void do_unpack(uvm::uvm_packer& p);
            virtual void do_copy(const uvm::uvm_object& rhs);
            virtual bool do_compare(const uvm_object& rhs) const;
            std::string convert2string() const;
    };
}

#endif /* APB_RW_ */
