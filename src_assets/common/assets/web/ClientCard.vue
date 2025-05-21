<template>
    <div class="card p-2">
        <div class="card-body">
            <h2>{{ $t('client_card.clients') }}</h2>
            <br>
            <!-- IP Information -->
            <div class="ip-info mb-4">
                <div class="mb-3">
                    <label class="form-label">{{ $t('client_card.private_ip') }}</label>
                    <div class="input-group">
                        <input type="text" class="form-control" :value="privateIP" readonly>
                        <button class="btn btn-outline-secondary" @click="copyToClipboard(privateIP)">
                            <i class="fas fa-copy"></i>
                        </button>
                    </div>
                </div>
                <div class="mb-3">
                    <label class="form-label">{{ $t('client_card.public_ip') }}</label>
                    <div class="input-group">
                        <input type="text" class="form-control" :value="publicIP" readonly>
                        <button class="btn btn-outline-secondary" @click="copyToClipboard(publicIP)">
                            <i class="fas fa-copy"></i>
                        </button>
                    </div>
                </div>
            </div>
            
            <p>{{ $t('client_card.clients_desc') }}</p>
            <div class="card-group p-4 align-items-center">
                <a v-for="{ platform, icon, name, link } of clients" class="btn m-1" :class="[link && 'btn-success' || 'btn-secondary']" :href="link" target="_blank" @click="shouldOpen($event, link)"><i v-if="icon" :class="icon"></i> <span class="platform-text">{{ platform }}</span> [ {{ name }} ] </a>
            </div>
            <i>* {{ $t('client_card.generic_moonlight_clients_desc') }}</i>
        </div>
    </div>
</template>

<style scoped>
    .platform-text {
        font-weight: bold;
    }
    .ip-info input {
        font-family: monospace;
    }
</style>

<script setup>
import { ref, onMounted } from 'vue';

const privateIP = ref('Loading...');
const publicIP = ref('Loading...');

const clients = [
        {
            platform: 'Android',
            icon: 'fa-brands fa-android',
            name: 'Artemis',
            link: 'https://github.com/ClassicOldSong/moonlight-android'
        },
        {
            platform: 'iOS',
            icon: 'fa-brands fa-apple',
            name: 'Coming soon...',
            link: ''
        },
        {
            platform: 'Desktop',
            icon: 'fa-solid fa-desktop',
            name: 'Coming soon...',
            link: ''
        }
    ]

const shouldOpen = (e, link) => {
    if (!link) {
        e.preventDefault();
    }
}

const copyToClipboard = async (text) => {
    try {
        await navigator.clipboard.writeText(text);
    } catch (err) {
        console.error('Failed to copy text: ', err);
    }
}

const getPrivateIP = async () => {
    try {
        const response = await fetch('/api/ip/private');
        const data = await response.json();
        privateIP.value = data.ip;
    } catch (err) {
        privateIP.value = 'Error loading IP';
        console.error('Failed to get private IP: ', err);
    }
}

const getPublicIP = async () => {
    try {
        const response = await fetch('https://api.ipify.org?format=json');
        const data = await response.json();
        publicIP.value = data.ip;
    } catch (err) {
        publicIP.value = 'Error loading IP';
        console.error('Failed to get public IP: ', err);
    }
}

onMounted(() => {
    getPrivateIP();
    getPublicIP();
});
</script>
