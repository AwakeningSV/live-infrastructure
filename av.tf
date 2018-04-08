provider "digitalocean" {
    token = "${var.do_token}"
}

provider "cloudflare" {
    email = "${var.cf_email}"
    token = "${var.cf_token}"
}

data "template_file" "av_cloud_config" {
    template = "${file("ignition.json")}"
    vars {
        publish_secret = "${var.publish_secret}"
    }
}

resource "digitalocean_ssh_key" "av" {
    name = "Alt AV SSH Key"
    public_key = "${file("${var.ssh_key_file}")}"
}

resource "digitalocean_droplet" "av1" {
    count = 1
    name = "av1.${var.cf_domain}"
    size = "16gb"
    image = "coreos-stable"
    region = "sfo1"
    ssh_keys = ["${digitalocean_ssh_key.av.id}"]
    user_data = "${data.template_file.av_cloud_config.rendered}"
}

resource "cloudflare_record" "av1" {
    domain = "${var.cf_domain}"
    name = "av1"
    value = "${digitalocean_droplet.av1.ipv4_address}"
    type = "A"
    ttl = 120
    proxied = false
}

resource "cloudflare_record" "live" {
    domain = "${var.cf_domain}"
    name = "live"
    value = "${digitalocean_droplet.av1.ipv4_address}"
    type = "A"
    ttl = 120
    proxied = false
}
