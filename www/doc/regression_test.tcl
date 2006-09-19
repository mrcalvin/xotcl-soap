# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# +-+-+-+-+-+-+ +-+-+-+-+ +-+-+-+-+-+
# |x|o|s|o|a|p| |t|e|s|t| |s|u|i|t|e|
# +-+-+-+-+-+-+ +-+-+-+-+ +-+-+-+-+-+
# author: stefan.sobernig@wu-wien.a.at
# cvs-id: $Id: xorb-aux-procs.tcl 10 2006-07-21 15:57:15Z ssoberni $
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

Object test
test set passed 0
test set failed 0
test proc case msg {ad_return_top_of_page "<title>$msg</title><h2>$msg</h2>"} 
test proc section msg    {my reset; ns_write "<hr><h3>$msg</h3>"} 
test proc subsection msg {ns_write "<h4>$msg</h4>"} 
test proc errmsg msg     {ns_write "ERROR: $msg<BR/>"; test incr failed}
test proc okmsg msg      {ns_write "OK: $msg<BR/>"; test incr passed}
test proc code msg       {ns_write "<pre>$msg</pre>"}
test proc reset {} {
  array unset ::xotcl_cleanup
  global af_parts  af_key_name
  array unset af_parts
  array unset af_key_name
}

proc ? {cmd expected {msg ""}} {
   set r [uplevel $cmd]
   if {$msg eq ""} {set msg $cmd}
   if {$r ne $expected} {
     test errmsg "$msg returned '$r' ne '$expected'"
   } else {
     test okmsg "$msg - passed ([t1 diff] ms)"
   }
}


 Class Timestamp
  Timestamp instproc init {} {my set time [clock clicks -milliseconds]}
  Timestamp instproc diffs {} {
    set now [clock clicks -milliseconds]
    set ldiff [expr {[my exists ltime] ? [expr {$now-[my set ltime]}] : 0}]
    my set ltime $now
    return [list [expr {$now-[my set time]}] $ldiff]
  }
  Timestamp instproc diff {{-start:switch}} {
    lindex [my diffs] [expr {$start ? 0 : 1}]
  }

  Timestamp instproc report {{string ""}} {
    foreach {start_diff last_diff} [my diffs] break
    my log "--$string (${start_diff}ms, diff ${last_diff}ms)"
  }

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

Timestamp t1

test case "xorb/xosoap test cases"

test section "Basic Setup"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# ((title)) 			XOTcl version test
# ((description)) 	Verifies whether the adequate XOTcl version is installed: >1.4
# ((type)) 			Basic Setup
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

? {expr {$::xotcl::version < 1.4}} 0 "XOTcl Version $::xotcl::version >= 1.4"

ns_write "<p>
<hr>
 Tests passed: [test set passed]<br>
 Tests failed: [test set failed]<br>
 Tests Time: [t1 diff -start]ms<br>
" 