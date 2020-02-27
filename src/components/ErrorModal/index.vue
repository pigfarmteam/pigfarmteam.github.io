<template>
  <div class="modal animated fadeIn fast">
    <div class="modal-container">
      <button class="modal-close-btn" @click="() => store.isShowErrorModal = false" />
      <div class="modal-title red">
        Error
      </div>
      <div>
        {{store.errorMessage}}
      </div>
    </div>
  </div>
</template>

<script>
import _store from '../../store';

export default {
  data() {
    return {
      store: _store
    }
  }
}
</script>