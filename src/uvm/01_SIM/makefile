TC ?= apb_test
SEED ?= 1234

VCS_OPTS := -full64 -sverilog 
VCS_OPTS += -ntb_opts uvm-1.2 
VCS_OPTS += -timescale=1ns/1ps 
VCS_OPTS += -debug_access+all -kdb -lca 
VCS_OPTS += +incdir+./tb
VCS_OPTS += -cm line+cond+fsm+tgl+branch+assert 

SIM_OPTS := +UVM_TESTNAME=$(TC)
SIM_OPTS += +UVM_VERBOSITY=UVM_LOW
SIM_OPTS += +ntb_random_seed=$(SEED)
SIM_OPTS += -cm line+cond+fsm+tgl+branch+assert 
SIM_OPTS += -cm_dir coverage.vdb -l test.log
SIM_OPTS += -cm_name sim1 

VERDI_OPTS := -covdir coverage.vdb -dbdir simv.daidir -ssf novas.fsdb

.PHONY: compile sim clean

compile:
	vcs $(VCS_OPTS) -f ./filelist.f -o simv


sim: compile
	./simv $(SIM_OPTS)

verdi: sim
	verdi $(VERDI_OPTS) &

vc:
	verdi -cov -covdir coverage.vdb &

vw:
	verdi -dbdir simv.daidir -ssf novas.fsdb &

clean:
	rm -rf simv* csrc *.key *.h *.log novas.* *.fsdb *.conf *Log inter.* coverage.*
