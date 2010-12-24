#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include <ruby.h>

#ifndef _XOPEN_SOURCE
#define _XOPEN_SOURCE 600
#endif

#include <assert.h>

int  ProfilerStart(const char*);
void ProfilerStop();
void ProfilerFlush();
void ProfilerRecord(int, void*, void*);
int  ProfilingIsEnabledForAllThreads();


#ifdef RUBY18
  #include <env.h>
  #include <node.h>
  #include <setjmp.h>
  #include <signal.h>
#endif

/* CpuProfiler */

static VALUE cPerfTools;
static VALUE cCpuProfiler;
static VALUE eError;
static VALUE bProfilerRunning;

static VALUE
cpuprofiler_running_p(VALUE self)
{
  return bProfilerRunning;
}

static VALUE
cpuprofiler_stop(VALUE self)
{
  if (!bProfilerRunning)
    return Qfalse;

  bProfilerRunning = Qfalse;
  ProfilerStop();
  ProfilerFlush();

  return Qtrue;
}

static VALUE
cpuprofiler_start(VALUE self, VALUE filename)
{
  StringValue(filename);

  if (bProfilerRunning)
    rb_raise(eError, "profiler is already running");

  if (getenv("CPUPROFILE_OBJECTS"))
    objprofiler_setup();
  else if (getenv("CPUPROFILE_METHODS"))
    methprofiler_setup();

  if (ProfilerStart(RSTRING_PTR(filename))) {
    bProfilerRunning = Qtrue;
  } else {
    rb_raise(eError, "profiler could not be started");
  }

  if (rb_block_given_p()) {
    rb_yield(Qnil);
    cpuprofiler_stop(self);
  }

  return Qtrue;
}

/* Init */

static void
profiler_at_exit(VALUE self)
{
  cpuprofiler_stop(self);
}

void
Init_vm_perftools()
{
  cPerfTools = rb_define_class("PerfTools", rb_cObject);
  eError = rb_define_class_under(cPerfTools, "Error", rb_eStandardError);
  cCpuProfiler = rb_define_class_under(cPerfTools, "CpuProfiler", rb_cObject);

  rb_define_singleton_method(cCpuProfiler, "running?", cpuprofiler_running_p, 0);
  rb_define_singleton_method(cCpuProfiler, "start", cpuprofiler_start, 1);
  rb_define_singleton_method(cCpuProfiler, "stop", cpuprofiler_stop, 0);

  if (ProfilingIsEnabledForAllThreads()) { // profiler is already running?
    bProfilerRunning = Qtrue;

    if (getenv("CPUPROFILE_OBJECTS")) {    // want to profile objects
      objprofiler_setup();
    } else if (getenv("CPUPROFILE_METHODS")) {
      methprofiler_setup();
    }

    rb_set_end_proc(profiler_at_exit, 0);  // make sure to cleanup before the VM shuts down
  }
}
