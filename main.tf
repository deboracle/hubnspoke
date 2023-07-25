# call hub module
module "hub" {
    source = "./modules/hub"
    location = var.location
}

# call work spoke module
module "work_spoke" {
    source = "./modules/work_spoke"
    location = var.location
}

# call monitor spoke module
module "monitor_spoke" {
    source = "./modules/monitor_spoke"
    location = var.location
}