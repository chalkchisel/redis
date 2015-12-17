#!/bin/bash

if [ "${REDISCONF_PASS}" == "**Random**" ]; then
    unset REDISCONF_PASS
fi

# Set initial configuration
if [ ! -f /.redis_configured ]; then
    touch /etc/redis/redis_default.conf

    if [ "${REDISCONF_PASS}" != "**None**" ]; then
        PASS=${REDISCONF_PASS:-$(pwgen -s 32 1)}
        _word=$( [ ${REDISCONF_PASS} ] && echo "preset" || echo "random" )
        echo "=> Securing redis with a ${_word} password"
        echo "requirepass $PASS" >> /etc/redis/redis_default.conf
        echo "=> Done!"
        echo "========================================================================"
        echo "You can now connect to this Redis server using:"
        echo ""
        echo "    redis-cli -a $PASS -h <host> -p <port>"
        echo ""
        echo "Please remember to change the above password as soon as possible!"
        echo "========================================================================"
    fi

    unset REDISCONF_PASS

    # Backwards compatibility
    if [ ! -z "${REDISCONF_MODE}" ]; then
        echo "!! WARNING: \$REDISCONF_MODE is deprecated. Please use \$REDISCONF_MAXMEMORY_POLICY instead"
        if [ "${REDISCONF_MODE}" == "LRU" ]; then
            export REDISCONF_MAXMEMORY_POLICY=allkeys-lru
            unset REDISCONF_MODE
        fi
    fi

    for i in $(printenv | grep REDISCONF_); do
        echo $i | sed "s/REDISCONF_//" | sed "s/_/-/" | sed "s/=/ /" | sed "s/^[^ ]*/\L&\E/" >> /etc/redis/redis_default.conf
    done

    echo "=> Using redis.conf:"
    cat /etc/redis/redis_default.conf | grep -v "requirepass"

    touch /.redis_configured
fi

exec /usr/bin/redis-server /etc/redis/redis_default.conf
