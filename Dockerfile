FROM opensuse/tumbleweed

MAINTAINER "Johannes Segitz <jsegitz@suse.de>"

RUN zypper refs && zypper refresh && zypper --non-interactive in ruby audit
ADD avcs.rb /usr/local/bin/avcs.rb
RUN chmod +x /usr/local/bin/avcs.rb

ENTRYPOINT ["/usr/local/bin/avcs.rb"]
