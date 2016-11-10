defmodule GnExec.Cmd.Lmmpy do

  #@behaviour GnExec.Cmd

 def script(geno, pheno) do
   """
/Users/bonnalraoul/anaconda3/envs/py27/bin/python /Users/bonnalraoul/Documents/Projects/gn/pylmm_gn2/bin/runlmm.py --geno=#{geno} --pheno=#{pheno} run
"""
 end
end
