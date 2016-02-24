#
# Cookbook Name:: learn-the-basics-ubuntu
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
LearnChef::Workflow::Audit::node = node
include_recipe 'learn-the-basics-ubuntu::setup'
include_recipe 'learn-the-basics-ubuntu::lesson1'
include_recipe 'learn-the-basics-ubuntu::lesson2'
include_recipe 'learn-the-basics-ubuntu::lesson3'
