
context("cpo cbind")


test_that("cbind building works", {

  expect_equal(length(cpoCbind(cpomultiplier.nt.o(), NULLCPO)$unexported.pars$.CPO), 3)
  expect_equal(length(cpoCbind(cpomultiplier.nt.o(), NULLCPO)$unexported.pars$.CPO[[3]]$parents), 2)

  expect_equal(length(cpoCbind(cpomultiplier.nt.o(), NULLCPO, copy = NULLCPO)$unexported.pars$.CPO[[3]]$parents), 3)


  twice = cpoCbind(cpomultiplier.nt.o(), cpomultiplier.nt.o())

  expect_error(cpoCbind(cpomultiplier.nt.o(), cpomultiplier.nt.o(factor = 3)), "ambiguously identical")

  previ = cpoCbind(cpomultiplier.nt.o(), cpoadder.nt.o()) %>>% cpoadder.nt.o(id = "sndrow")

  route1 = cpoCbind(previ %>>% cpomultiplier.nt.o(id = "thrdrow"), previ, NULLCPO)

  route2 = cpoCbind(route1, previ %>>% cpoadder.nt.o(id = "frthrow")) %>>% cpomultiplier.nt.o(id = "sxthrow")

  expect_error(cpoCbind(setHyperPars(previ, multiplierO.factor = 10) %>>% cpomultiplier.nt.o(id = "thrdrow"), previ, NAME = NULLCPO),
               "multiplier.*ambiguously identical")

  route3error = cpoCbind(previ %>>% cpomultiplier.nt.o(id = "thrdrow", factor = -1), previ, NAME = NULLCPO)

  expect_error(cpoCbind(route1, route2, route3error), "thrdrow.*ambiguously identical")

  route3 = cpoCbind(previ %>>% cpomultiplier.nt.o(id = "thrdrow"), previ, NAME = NULLCPO)

  result = cpoCbind(route1, route2, route3)

  # expected length: 1 source, 5 CPOs, 5 CBINDs ==> 12
  expect_length(result$unexported.pars$.CPO, 12)


  expect_error(cpoCbind(NULLCPO, NULLCPO), "Duplicating inputs.*unnamed")

  expect_error(cpoCbind(NULLCPO, NULLCPO, a = NULLCPO, b = NULLCPO, c = NULLCPO, a = NULLCPO), "Duplicating input.*entries a\\.")
  expect_error(cpoCbind(NULLCPO, NULLCPO, a = NULLCPO, b = NULLCPO, c = NULLCPO, d = NULLCPO), "Duplicating input.*unnamed")

})

test_that("cbind with NULLCPO works", {

  copier = cpoCbind(NULLCPO, copy = NULLCPO)

  cop = cpo.df1 %>>% copier

  expect_equal(cpo.df1 %>>% retrafo(cop), data.frame(cpo.df1, copy = cpo.df1))
  retrafo(cop) = NULL
  expect_equal(cop, data.frame(cpo.df1, copy = cpo.df1))

  copycopy = cpoCbind(copier, copyx = copier, copyy = copier)

  indf = data.frame(a = 1:3, b = -3:-1)
  expected = data.frame(indf, copy = indf, copyx = indf, copyx.copy = indf, copyy = indf, copyy.copy = indf)
  result = indf %>>% copycopy
  expect_equal(indf %>>% retrafo(result), expected)
  retrafo(result) = NULL
  expect_equal(result, expected)

  result = cpo.df1c %>>% copycopy
  indf = cpo.df1[c(1, 2, 3, 5)]
  expected = data.frame(cpo.df1[4], indf, copy = indf, copyx = indf, copyx.copy = indf, copyy = indf, copyy.copy = indf)

  expect_equal(getTaskData(result), expected)
  expect_equal(cpo.df1 %>>% retrafo(result), cbind(expected[-1], expected[1]))

})

test_that("cbind does what it is supposed to do", {

  df = data.frame(a = 1:3, b = -3:-1)
  df2 = data.frame(a = 1:3 * 3, b = -3:-1 - 10)

  cpo.clist = numeric(0)

  mul = makeCPOObject("multiplierO", factor = 1: numeric[~., ~.], .dataformat = "df.features", cpo.trafo = {
    cpo.clist <<- c(cpo.clist, data[[1]][1])  # nolint
    data[[1]] = data[[1]] * factor
    data[[2]] = data[[2]] * factor
    control = 0
    data
  }, cpo.retrafo = {
    cpo.clist <<- c(cpo.clist, data[[1]][1])  # nolint
    data[[1]] = data[[1]] / factor
    data
  })


  add = makeCPOObject("adderO", summand = 1: integer[, ], .dataformat = "df.features", cpo.trafo = {
    cpo.clist <<- c(cpo.clist, data[[1]][1])  # nolint
    control = mean(data[[1]])
    data[[1]] = data[[1]] + summand
    data[[2]] = data[[2]] + summand
    data
  }, cpo.retrafo = {
    cpo.clist <<- c(cpo.clist, data[[1]][1])  # nolint
    data[[1]] = data[[1]] - summand - control
    data[[2]] = data[[2]] - summand - control
    data
  })




  pre = cpoCbind(mul1 = mul(id = "lvl1", factor = 10), add1 = add(id = "lvl1", summand = 10))

  cpo.clist = numeric(0)
  result = df %>>% pre
  expect_equal(cpo.clist, c(1, 1))
  expect_equal(df %>>% retrafo(result), data.frame(mul1.a = 1:3 / 10, mul1.b = -3:-1, add1.a = 1:3 - 10 - 2, add1.b = -3:-1 - 10 - 2))
  retrafo(result) = NULL
  expect_equal(result, data.frame(mul1.a = 1:3 * 10, mul1.b = -3:-1 * 10, add1.a = 1:3 + 10, add1.b = -3:-1 + 10))





  route1 = cpoCbind(mul2 = pre %>>% mul(id = "sndrow", factor = 2), pre %>>% cpoSelect(index = c(4, 3, 2, 1)), copy1 = NULLCPO)
  route1 = setHyperPars(route1, sndrow.factor = 4)
  cpo.clist = numeric(0)
  checkroute1 = df %>>% route1
  checkroute1retrafo = df2 %>>% retrafo(checkroute1)
  retrafo(checkroute1) = NULL
  clist1 = cpo.clist

  cpo.clist = numeric(0)
  predf = df %>>% pre
  predf.rt = df2 %>>% retrafo(predf)
  retrafo(predf) = NULL
  tmp1 = predf %>>% mul(4)
  tmp2 = predf %>>% cpoSelect(index = c(4, 3, 2, 1))
  route1df = data.frame(mul2 = tmp1, tmp2, copy1 = df)
  clist1.df = cpo.clist
  cpo.clist = numeric(0)


  route1df.rt = data.frame(mul2 = predf.rt %>>% retrafo(tmp1), predf.rt %>>% retrafo(tmp2), copy1 = df2)

  expect_equal(checkroute1, route1df)
  expect_equal(checkroute1retrafo, route1df.rt)
  clist1.df.rt = cpo.clist
  # clist gets set by the CPOs whenever they are called
  # while the order in which they are called (and write their characteristic
  # values into clist) may vary, the values themselves should be the same
  # if each CPO gets called the same amount of times and with the same data
  # in both cpoCbind and manual application.
  expect_set_equal(clist1, c(clist1.df, clist1.df.rt))


  route2 = cpoCbind(route1, add3 = pre %>>% add(id = "thrdrow")) %>>% mul(id = "frthrow", factor = 3)
  checkroute2 = df %>>% setHyperPars(route2, sndrow.factor = 9)
  checkroute2retrafo = df2 %>>% retrafo(checkroute2)
  retrafo(checkroute2) = NULL

  route1df = data.frame(mul2 = predf %>>% mul(9), predf %>>% cpoSelect(index = c(4, 3, 2, 1)), copy1 = df)
  route1df.rt = data.frame(mul2 = predf.rt %>>% retrafo(predf %>>% mul(9)), predf.rt %>>% retrafo(predf %>>% cpoSelect(index = c(4, 3, 2, 1))), copy1 = df2)

  route2df = data.frame(route1df, add3 = predf %>>% add(id = "thrdrow")) %>>% mul(id = "frthrow", factor = 3)
  route2df.rt = data.frame(route1df.rt, add3 = predf.rt %>>% retrafo(predf %>>% add(id = "thrdrow"))) %>>% retrafo(route2df)
  retrafo(route2df) = NULL

  expect_equal(checkroute2, route2df)
  expect_equal(checkroute2retrafo, route2df.rt)


  route3 = cpoCbind(mul4 = pre %>>% mul(id = "ffthrow", factor = 1.2), cpoSelect(index = c(2, 1), id = "select2") %>>%  cpoWrap(pre), copy2 = NULLCPO)
  result = setHyperPars(cpoCbind(r1 = route1, r2 = route2, r3 = route3), lvl1.summand = 20)

  cpo.clist = numeric(0)
  fullroute = df %>>% result
  fullroute.trafo.clist = cpo.clist

  cpo.clist = numeric(0)
  fullrouteretrafo = df2 %>>% retrafo(fullroute)
  fullroute.retrafo.clist = cpo.clist
  retrafo(fullroute) = NULL


  cpo.clist = numeric(0)
  tmp1 = df %>>% mul(factor = 10)
  tmp2 = df %>>% add(summand = 20)
  predf = data.frame(mul1 = tmp1, add1 = tmp2)

  tmp3 = predf %>>% mul(4)
  tmp4 = predf %>>% cpoSelect(index = c(4, 3, 2, 1))
  route1df = data.frame(mul2 = tmp3, tmp4, copy1 = df)

  tmp5 = predf %>>% add(id = "thrdrow")
  route2df = data.frame(route1df, add3 = tmp5) %>>% mul(id = "frthrow", factor = 3)

  df.select = df %>>% cpoSelect(index = c(2, 1))
  rtselect = retrafo(df.select)
  retrafo(df.select) = NULL

  tmp6 = df.select %>>% mul(factor = 10)
  tmp7 = df.select %>>% add(summand = 10)
  preinsert = data.frame(mul1 = tmp6, add1 = tmp7)

  tmp8 = predf %>>% mul(factor = 1.2)
  route3df = data.frame(mul4 = tmp8, preinsert, copy2 = df)

  fullroutedf = data.frame(r1 = route1df, r2 = route2df, r3 = route3df)
  fullroute.trafo.df.clist = cpo.clist


  cpo.clist = numeric(0)
  predf.rt = data.frame(mul1 = df2 %>>% retrafo(tmp1), add1 = df2 %>>% retrafo(tmp2))
  route1df.rt = data.frame(mul2 = predf.rt %>>% retrafo(tmp3), predf.rt %>>% retrafo(tmp4), copy1 = df2)
  route2df.rt = data.frame(route1df.rt, add3 = predf.rt %>>% retrafo(tmp5)) %>>% retrafo(route2df)
  df.select.rt = df2 %>>% rtselect
  preinsert.rt = data.frame(mul1 = df.select.rt %>>% retrafo(tmp6), add1 = df.select.rt %>>% retrafo(tmp7))
  route3df.rt = data.frame(mul4 = predf.rt %>>% retrafo(tmp8), preinsert.rt, copy2 = df2)
  fullroutedf.rt = data.frame(r1 = route1df.rt, r2 = route2df.rt, r3 = route3df.rt)

  fullroute.retrafo.df.clist = cpo.clist

  expect_equal(fullroute, fullroutedf)
  expect_equal(fullrouteretrafo, fullroutedf.rt)

  # see explanation of expect_set_equal above
  expect_set_equal(fullroute.trafo.clist, fullroute.trafo.df.clist)
  expect_set_equal(fullroute.retrafo.clist, fullroute.retrafo.df.clist)

  dftask = makeClassifTask("df", data.frame(c = factor(c("a", "b", "c")), df), target = "c")
  df2task = makeClassifTask("df2", data.frame(c = factor(c("x", "y", "x")), df2), target = "c")

  cpo.clist = numeric(0)
  fullroute.task = dftask %>>% result
  fullroute.task.trafo.clist = cpo.clist
  expect_equal(fullroute.task.trafo.clist, fullroute.trafo.clist)

  cpo.clist = numeric(0)
  fullrouteretrafo.task = df2task %>>% retrafo(fullroute.task)
  fullroute.task.retrafo.clist = cpo.clist
  expect_equal(fullroute.task.retrafo.clist, fullroute.retrafo.clist)

  expect_equal(getTaskData(fullroute.task, target.extra = TRUE)$data, fullroutedf)
  expect_equal(getTaskData(fullrouteretrafo.task, target.extra = TRUE)$data, fullroutedf.rt)

})
