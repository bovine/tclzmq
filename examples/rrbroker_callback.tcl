#
# Simple request-reply broker
#

package require tclzmq

# Prepare our context and sockets
tclzmq::context context 1
tclzmq::socket frontend context ROUTER
tclzmq::socket backend context DEALER
frontend bind "tcp://*:5559"
backend bind "tcp://*:5560"

# Worker procs
proc process_frontend {} {
    while {1} {
	# Process all parts of the message
	tclzmq::message message
	::frontend recv message
	set more [::frontend getsockopt RCVMORE]
	::backend send message [expr {$more?"SNDMORE":""}]
	message close
	if {!$more} {
	    break ; # Last message part
	}
    }
}

proc process_backend {} {
    while {1} {
	# Process all parts of the message
	tclzmq::message message
	::backend recv message
	set more [::backend getsockopt RCVMORE]
	::frontend send message [expr {$more?"SNDMORE":""}]
	message close
	if {!$more} {
	    break ; # Last message part
	}
    }
}

# Switch messages between sockets
frontend readable [list process_frontend]
backend readable [list process_backend]

vwait forever

# We never get here but clean up anyhow
frontend close
backend close
context term
