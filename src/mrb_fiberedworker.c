/*
** mrb_fiberedworker.c - FiberedWorker class
**
** Copyright (c) Uchio Kondo 2018
**
** See Copyright Notice in LICENSE
*/

#include "mruby.h"
#include "mruby/data.h"
#include "mrb_fiberedworker.h"

#define DONE mrb_gc_arena_restore(mrb, 0);

typedef struct {
  char *str;
  int len;
} mrb_fiberedworker_data;

static const struct mrb_data_type mrb_fiberedworker_data_type = {
  "mrb_fiberedworker_data", mrb_free,
};

static mrb_value mrb_fiberedworker_init(mrb_state *mrb, mrb_value self)
{
  mrb_fiberedworker_data *data;
  char *str;
  int len;

  data = (mrb_fiberedworker_data *)DATA_PTR(self);
  if (data) {
    mrb_free(mrb, data);
  }
  DATA_TYPE(self) = &mrb_fiberedworker_data_type;
  DATA_PTR(self) = NULL;

  mrb_get_args(mrb, "s", &str, &len);
  data = (mrb_fiberedworker_data *)mrb_malloc(mrb, sizeof(mrb_fiberedworker_data));
  data->str = str;
  data->len = len;
  DATA_PTR(self) = data;

  return self;
}

static mrb_value mrb_fiberedworker_hello(mrb_state *mrb, mrb_value self)
{
  mrb_fiberedworker_data *data = DATA_PTR(self);

  return mrb_str_new(mrb, data->str, data->len);
}

static mrb_value mrb_fiberedworker_hi(mrb_state *mrb, mrb_value self)
{
  return mrb_str_new_cstr(mrb, "hi!!");
}

void mrb_mruby_fibered_worker_gem_init(mrb_state *mrb)
{
  struct RClass *fiberedworker;
  fiberedworker = mrb_define_class(mrb, "FiberedWorker", mrb->object_class);
  mrb_define_method(mrb, fiberedworker, "initialize", mrb_fiberedworker_init, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, fiberedworker, "hello", mrb_fiberedworker_hello, MRB_ARGS_NONE());
  mrb_define_class_method(mrb, fiberedworker, "hi", mrb_fiberedworker_hi, MRB_ARGS_NONE());
  DONE;
}

void mrb_mruby_fibered_worker_gem_final(mrb_state *mrb)
{
}

